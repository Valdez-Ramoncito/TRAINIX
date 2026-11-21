enum SpeakingPack { readAloud, callOpenings, grammarDrills, freeResponse }

extension SpeakingPackInfo on SpeakingPack {
  String get label {
    switch (this) {
      case SpeakingPack.readAloud:
        return 'Read Aloud';
      case SpeakingPack.callOpenings:
        return 'Call Openings';
      case SpeakingPack.grammarDrills:
        return 'Grammar Drills';
      case SpeakingPack.freeResponse:
        return 'Free Response';
    }
  }

  String get hint {
    switch (this) {
      case SpeakingPack.readAloud:
        return 'Read the script at a steady pace. Pronunciation clarity is scored from the audio.';
      case SpeakingPack.callOpenings:
        return 'Open the call with a greeting, your name, and the reason for the call.';
      case SpeakingPack.grammarDrills:
        return 'Read the sentence and keep the target pattern intact.';
      case SpeakingPack.freeResponse:
        return 'Answer the customer situation and cover every required point.';
    }
  }
}

enum SpeakingPromptDifficulty { short, medium, long }

extension SpeakingPromptDifficultyInfo on SpeakingPromptDifficulty {
  String get label {
    switch (this) {
      case SpeakingPromptDifficulty.short:
        return 'Short';
      case SpeakingPromptDifficulty.medium:
        return 'Medium';
      case SpeakingPromptDifficulty.long:
        return 'Long';
    }
  }
}

class SpeakingPrompt {
  final String id;
  final String text;
  final SpeakingPack pack;
  final SpeakingPromptDifficulty difficulty;
  final String label;
  final int targetSeconds;
  final List<String> focus;
  final List<String> requiredPoints;

  const SpeakingPrompt({
    required this.id,
    required this.text,
    required this.pack,
    required this.difficulty,
    required this.label,
    required this.targetSeconds,
    this.focus = const [],
    this.requiredPoints = const [],
  });

  int get wordCount {
    final parts = text.trim().split(RegExp(r'\s+'));
    if (parts.length == 1 && parts.first.isEmpty) return 0;
    return parts.length;
  }

  int get charCount => text.length;
}
