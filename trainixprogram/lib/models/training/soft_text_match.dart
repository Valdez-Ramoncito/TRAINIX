class SoftTextMatch {
  static final _punct = RegExp(r"[^\w\s']");
  static final _spaces = RegExp(r'\s+');
  static const _stop = {
    'the',
    'a',
    'an',
    'to',
    'for',
    'of',
    'and',
    'or',
    'is',
    'are',
    'was',
    'were',
    'this',
    'that',
    'you',
    'i',
    'me',
    'my',
    'your',
    'with',
    'on',
    'in',
    'at',
    'it',
    'be',
    'as',
    'do',
    'how',
    'may',
    'can',
    'will',
  };

  static String normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(_punct, ' ')
        .replaceAll(_spaces, ' ')
        .trim();
  }

  static List<String> contentWords(String normalized) {
    return normalized
        .split(' ')
        .where((w) => w.length > 1 && !_stop.contains(w))
        .toList();
  }

  static bool typingMatches(String input, String target) {
    final a = normalize(input);
    final b = normalize(target);
    if (a.isEmpty || b.isEmpty) return false;
    if (a == b) return true;
    if (a.contains(b) || b.contains(a)) return true;

    final at = contentWords(a);
    final bt = contentWords(b);
    if (bt.isEmpty) return a == b;

    var hits = 0;
    for (final w in bt) {
      final found = at.any((x) {
        if (x == w) return true;
        if (x.length >= 4 && w.length >= 4) {
          if (x.startsWith(w) || w.startsWith(x)) return true;
          if (x.contains(w) || w.contains(x)) return true;
        }
        return false;
      });
      if (found) hits++;
    }
    return hits / bt.length >= 0.65;
  }
}
