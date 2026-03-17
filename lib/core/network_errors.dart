/// Maps low-level network exceptions to short, actionable copy for users.
String friendlyNetworkMessage(Object error) {
  final s = error.toString().toLowerCase();
  if (s.contains('failed host lookup') ||
      s.contains('no address associated with hostname') ||
      s.contains('socketexception') ||
      s.contains('network is unreachable') ||
      s.contains('connection refused') ||
      s.contains('timed out') ||
      s.contains('clientexception')) {
    return 'No connection to server.\n\n'
        '• Turn on mobile data or Wi‑Fi\n'
        '• Try the other network (Wi‑Fi ↔ mobile data)\n'
        '• Settings → Network → turn off Private DNS, or set DNS to Automatic\n'
        '• Turn off VPN / ad‑blocker briefly and try again\n'
        '• Then tap Sign in again';
  }
  return error.toString();
}

bool looksLikeNetworkError(Object e) {
  final s = e.toString().toLowerCase();
  return s.contains('socketexception') ||
      s.contains('failed host lookup') ||
      s.contains('clientexception') ||
      s.contains('network') ||
      s.contains('connection');
}
