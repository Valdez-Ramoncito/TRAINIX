class UserFacingMessages {
  static const connectionProblem =
      'Connection problem. Check your network and try again.';
  static const couldNotReachCustomer =
      'Could not reach the customer. Please try again in a moment.';
  static const microphoneUnavailable =
      'Microphone is not available. Check permissions and try again.';
  static const somethingWentWrong = 'Something went wrong. Please try again.';
  static const audioUnavailable = 'Recording is not available for this line.';
  static const startingSession = 'Starting...';
  static const sending = 'Sending...';
  static const retrying = 'Retrying...';
}

/// Strip internal competency codes from text shown to trainees.
String friendlyEvalText(String raw) {
  var t = raw.trim();
  if (t.isEmpty || t.toUpperCase() == 'N/A') return '';
  t = t.replaceAll(RegExp(r'\bICT\d+\b', caseSensitive: false), '');
  t = t.replaceAll(RegExp(r'\bCore Unit\s*\d+\b', caseSensitive: false), '');
  t = t.replaceAll(RegExp(r'\bCommon Unit\s*\d+\b', caseSensitive: false), '');
  t = t.replaceAll(
    RegExp(r'\bBasic Competency\s*\d+\b', caseSensitive: false),
    '',
  );
  t = t.replaceAll(RegExp(r'\bTESDA\b', caseSensitive: false), '');
  t = t.replaceAll(RegExp(r'\bNC\s*II\b', caseSensitive: false), '');
  t = t.replaceAll(
    RegExp(r'\bcontact[- ]center\b', caseSensitive: false),
    'call center',
  );
  t = t.replaceAll(RegExp(r'Per\$\d+\b'), 'Personally,');
  t = t.replaceAll(RegExp(r'\$\d+\b'), '');
  t = t.replaceAll(RegExp(r'\(\s*[,;:\-\s]*\)'), '');
  t = t.replaceAll(RegExp(r'\s{2,}'), ' ');
  t = t.replaceAll(RegExp(r'\s+([,.;])'), r'$1');
  t = t.replaceAllMapped(RegExp(r'\.\s+([A-Z])'), (m) => '.\n\n${m.group(1)}');
  return t.trim();
}
