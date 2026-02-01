/// Single source of truth for embed mode detection.
class EmbedContext {
  final bool isEmbed;
  final String? targetUid;

  const EmbedContext({required this.isEmbed, this.targetUid});

  /// Creates EmbedContext from URI.
  /// Supports two URL formats:
  /// 1. Root with query param: /?embed=1&targetUid=XXX
  /// 2. Chat detail with path: /chat/XXX?embed=1
  EmbedContext.fromUri(Uri uri, {String? pathTargetUid})
    : isEmbed = uri.queryParameters['embed'] == '1',
      targetUid = pathTargetUid ?? uri.queryParameters['targetUid'];

  /// Returns true if embed mode is active but targetUid is missing or empty.
  bool get isMissingTargetUid =>
      isEmbed && (targetUid == null || targetUid!.isEmpty);

  /// Returns true if embed mode is properly configured.
  bool get isValidEmbed =>
      isEmbed && targetUid != null && targetUid!.isNotEmpty;
}
