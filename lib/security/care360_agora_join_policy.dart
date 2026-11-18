/// Fail-closed client-side preflight for Agora calls. The server must also
/// authorize both clinicians and patients for an active appointment and mint
/// short-lived per-session Agora tokens.
class Care360AgoraJoinPolicy {
  static bool _present(String? value) {
    final text = value?.trim() ?? '';
    return text.isNotEmpty && text != 'null' && text != 'N_A';
  }

  static bool canJoin({
    required String? sessionToken,
    required String? agoraToken,
    required String? channelId,
    required String? appId,
    required bool outgoing,
    int? remoteUserId,
  }) {
    if (!_present(sessionToken) || !_present(agoraToken) ||
        !_present(channelId) || !_present(appId)) {
      return false;
    }
    if (channelId!.trim().length > 128 || appId!.trim().length > 128) {
      return false;
    }
    if (outgoing && (remoteUserId == null || remoteUserId <= 0)) {
      return false;
    }
    return true;
  }
}
