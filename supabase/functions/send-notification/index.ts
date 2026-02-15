import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const SCOPES = ["https://www.googleapis.com/auth/firebase.messaging"];
const FCM_SEND_URL =
  "https://fcm.googleapis.com/v1/projects/{PROJECT_ID}/messages:send";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

// ── Base64URL helpers ────────────────────────────────────────────────────────

function base64UrlEncode(data: string): string {
  return btoa(data).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function base64UrlToBase64(b64url: string): string {
  let b64 = b64url.replace(/-/g, "+").replace(/_/g, "/");
  while (b64.length % 4 !== 0) b64 += "=";
  return b64;
}

// ── RSA sign with PKCS#8 key ─────────────────────────────────────────────────

async function signRSA(
  privateKeyPem: string,
  data: Uint8Array
): Promise<ArrayBuffer> {
  // Strip PEM headers and decode
  const pemBody = privateKeyPem
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\s/g, "");

  const binaryKey = Uint8Array.from(atob(pemBody), (c) => c.charCodeAt(0));

  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    binaryKey,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"]
  );

  return crypto.subtle.sign("RSASSA-PKCS1-v1_5", cryptoKey, data as ArrayBuffer);
}

// ── Generate Google OAuth2 access token from service account ─────────────────

async function getAccessToken(serviceAccount: {
  client_email: string;
  private_key: string;
  token_uri: string;
  project_id: string;
}): Promise<{ access_token: string; project_id: string }> {
  const now = Math.floor(Date.now() / 1000);

  const header = base64UrlEncode(JSON.stringify({ alg: "RS256", typ: "JWT" }));

  const payload = base64UrlEncode(
    JSON.stringify({
      iss: serviceAccount.client_email,
      scope: SCOPES.join(" "),
      aud: serviceAccount.token_uri,
      iat: now,
      exp: now + 3600,
    })
  );

  const unsignedJwt = `${header}.${payload}`;
  const signature = await signRSA(
    serviceAccount.private_key,
    new TextEncoder().encode(unsignedJwt)
  );

  const sig64 = base64UrlEncode(
    String.fromCharCode(...new Uint8Array(signature))
  );
  const jwt = `${unsignedJwt}.${sig64}`;

  // Exchange JWT for access token
  const tokenRes = await fetch(serviceAccount.token_uri, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });

  if (!tokenRes.ok) {
    const errText = await tokenRes.text();
    throw new Error(`Token exchange failed: ${tokenRes.status} - ${errText}`);
  }

  const tokenData = await tokenRes.json();
  return {
    access_token: tokenData.access_token,
    project_id: serviceAccount.project_id,
  };
}

// ── Main handler ─────────────────────────────────────────────────────────────

Deno.serve(async (req: Request) => {

  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const { fcm_token, title, body, data } = await req.json();

    if (!fcm_token || !title || !body) {
      return new Response(
        JSON.stringify({ error: "Missing required fields: fcm_token, title, body" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Fetch service account secret from Supabase Vault
    const serviceAccountJson = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");
    if (!serviceAccountJson) {
      throw new Error("FIREBASE_SERVICE_ACCOUNT secret not found");
    }

    const serviceAccount = JSON.parse(serviceAccountJson);

    // Generate access token
    const { access_token, project_id } = await getAccessToken(serviceAccount);

    // Build FCM v1 endpoint
    const url = FCM_SEND_URL.replace("{PROJECT_ID}", project_id);

    // Build FCM v1 message payload
    const message: Record<string, unknown> = {
      message: {
        token: fcm_token,
        notification: { title, body },
        android: {
          priority: "high",
          notification: {
            channel_id: "chat_messages",
            sound: "default",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
            },
          },
        },
        ...(data ? { data } : {}),
      },
    };

    // Send to FCM
    const fcmRes = await fetch(url, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${access_token}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(message),
    });

    const fcmBody = await fcmRes.json();

    if (!fcmRes.ok) {
      console.error("FCM error:", JSON.stringify(fcmBody));
      return new Response(
        JSON.stringify({ error: "FCM send failed", details: fcmBody }),
        { status: fcmRes.status, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    return new Response(
      JSON.stringify({ success: true, messageId: fcmBody.name }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    console.error("Edge function error:", err);
    return new Response(
      JSON.stringify({ error: (err as Error).message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
