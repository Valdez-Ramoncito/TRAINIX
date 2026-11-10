import 'package:trainixprogram/models/session_score.dart';
import 'package:trainixprogram/models/simulation_history.dart';

/// Strip internal codes and debug artifacts from text shown to trainees.
String friendlyEvalText(String raw) {
  var t = raw.trim();
  if (t.isEmpty || t.toUpperCase() == 'N/A') return '';

  final lower = t.toLowerCase();
  if (lower.contains('debug sample') ||
      lower.contains('debug scores') ||
      lower.contains('illustrative only') ||
      lower.startsWith('debug customer') ||
      lower.contains('debug customer')) {
    return '';
  }

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
  t = t.replaceAll(RegExp(r'\(debug sample\)', caseSensitive: false), '');
  t = t.replaceAll(RegExp(r'\bdebug sample\b', caseSensitive: false), '');
  t = t.replaceAll(RegExp(r'\(\s*[,;:\-\s]*\)'), '');
  t = t.replaceAll(RegExp(r'\s{2,}'), ' ');
  // Dart replaceAll does not expand $1 as a backreference. Use mapped replace.
  t = t.replaceAllMapped(RegExp(r'\s+([,.;])'), (m) => m.group(1)!);
  t = t.replaceAllMapped(RegExp(r'\.\s+([A-Z])'), (m) => '.\n\n${m.group(1)}');
  // Strip model artifacts and any leftover $n tokens from older cleaners.
  t = t.replaceAll(RegExp(r'\$\d+'), '');
  t = t.replaceAll(RegExp(r'\s{2,}'), ' ');
  t = t.trim();
  if (t.isEmpty) return '';
  if (RegExp(r'^[\W_]+$').hasMatch(t)) return '';
  return t;
}

bool isDebugCustomerName(String name) {
  final n = name.trim().toLowerCase();
  if (n.isEmpty) return false;
  return n.contains('debug') ||
      n.contains('sample') ||
      n.startsWith('demo ') ||
      n.startsWith('practice customer');
}

bool isDebugEvaluation(SessionEvaluation e) {
  final sector = e.sector.toLowerCase();
  final problem = e.problem.toLowerCase();
  return isDebugCustomerName(e.customerName) ||
      sector.contains('debug') ||
      problem.contains('debug sample') ||
      problem.contains('sample practice problem');
}

bool isDebugSession(PlayedSession session) {
  final sector = session.sector.toLowerCase();
  if (sector.contains('debug') || sector.contains('sample')) return true;
  if (session.evaluations.isEmpty) return false;
  return session.evaluations.every(isDebugEvaluation);
}

String friendlyCustomerName(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return 'Customer';
  if (isDebugCustomerName(t)) return 'Practice customer';
  return t;
}

String friendlyProblemText(String raw) {
  final cleaned = friendlyEvalText(raw);
  if (cleaned.isEmpty) return '';
  final lower = cleaned.toLowerCase();
  if (lower.contains('sample practice') || lower.contains('sample problem')) {
    return 'Practice scenario';
  }
  return cleaned;
}
