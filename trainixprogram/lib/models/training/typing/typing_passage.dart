enum TypingPack {
  general,
  scripts,
  chat,
}

enum TypingDifficulty {
  short,
  medium,
  long,
}

class TypingPassage {
  final String id;
  final String text;
  final TypingPack pack;
  final TypingDifficulty difficulty;
  final String label;

  const TypingPassage({
    required this.id,
    required this.text,
    required this.pack,
    required this.difficulty,
    required this.label,
  });

  int get charCount => text.length;

  int get wordCount {
    final parts = text.trim().split(RegExp(r'\s+'));
    if (parts.length == 1 && parts.first.isEmpty) return 0;
    return parts.length;
  }
}
