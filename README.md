# gh-pages

### 🕵️‍♂️ WHERE did these files come from?
These files come from the build results of the Flutter web application project. This specific build uses the standard **CanvasKit** renderer to ensure maximum stability and compatibility with third-party integrations like Firebase Auth and Cloud Messaging.

<br>

## 📋 Steps
Here is how to generate the following files:
- Go to the project directory: ```cd flutter_web_app```
- Run the build command: 
  ```bash
  flutter build web --release \
    --dart-define=GOOGLE_WEB_CLIENT_ID=YOUR_WEB_ID.apps.googleusercontent.com \
    --dart-define=VERCEL_API_URL=https://your-talkest-api.vercel.app
  ```
- This will create a new folder ```build/web/``` and its contents.
- Finally, all the contents of the ```build/web``` folder will be placed in this ```gh-pages``` branch.

<br>

## 📚 References
For more details on the web rendering architecture used in this build:

**[Flutter Docs - Web Renderers](https://docs.flutter.dev/platform-integration/web/renderers#command-line-options)**
> *"When building for the web, Flutter defaults to the `auto` render mode. It chooses the HTML renderer on mobile browsers and CanvasKit on desktop browsers to optimize for both payload size and rendering performance."*
