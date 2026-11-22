/// Applies light text-channel emotion cues to customer lines (non-voice).
/// Does not append stock waiting/urgency phrases onto complete scripted turns.
/// Voice uses Typecast presets; mission script lines should stay natural.
class CustomerEmotionStyle {
  /// Session heat ladder driven by agent behavior.
  /// 0 = base pack emotion, 1 = warmer, 2 = hot, 3 = angry peak.
  static String effectiveEmotion({
    required String baseEmotion,
    required int heatLevel,
  }) {
    final base = baseEmotion.trim().isEmpty ? 'neutral' : baseEmotion.trim();
    final level = heatLevel.clamp(0, 3);
    if (level <= 0) return base;
    final b = base.toLowerCase();
    if (level >= 3) return 'angry';
    if (level == 2) {
      if (b.contains('angry') || b.contains('upset')) return 'angry';
      return 'frustrated';
    }
    if (b.contains('angry') ||
        b.contains('upset') ||
        b.contains('frustrat') ||
        b.contains('impatient') ||
        b.contains('annoy')) {
      return base;
    }
    if (b.contains('disappoint') ||
        b.contains('worried') ||
        b.contains('anxious') ||
        b.contains('concern')) {
      return 'frustrated';
    }
    return 'impatient';
  }

  static int coolHeat(int heatLevel) => (heatLevel - 1).clamp(0, 3);

  static int raiseHeat(int heatLevel, {bool strong = false}) =>
      (heatLevel + (strong ? 2 : 1)).clamp(0, 3);

  static bool _isClosingOrResolved(String t) {
    final l = t.toLowerCase();
    return l.contains('thank you') ||
        l.contains('thanks') ||
        l.contains('that is all') ||
        l.contains("that's all") ||
        l.contains('all for today') ||
        l.contains('all i needed') ||
        l.contains('goodbye') ||
        l.contains('good bye') ||
        l.contains('resolved') ||
        l.contains('that helps') ||
        l.contains('appreciate') ||
        l.contains('have a good') ||
        l.contains('have a great');
  }

  static bool _isIdentityOrDataLine(String t) {
    final l = t.toLowerCase();
    return l.contains('account ends') ||
        l.contains('account ending') ||
        l.contains('member id') ||
        l.contains('card ends') ||
        l.contains('last four') ||
        RegExp(r'\baccount\s+\d{4,6}\b').hasMatch(l) ||
        RegExp(r'\bends?\s+\d{4}\b').hasMatch(l);
  }

  static bool _alreadyHasUrgency(String t) {
    final l = t.toLowerCase();
    return l.contains('waiting') ||
        l.contains('move faster') ||
        l.contains('supervisor') ||
        l.contains('unacceptable') ||
        l.contains('right now') ||
        l.contains('dismissive') ||
        l.contains('escalate') ||
        l.contains('no more excuses') ||
        l.contains('still here') ||
        l.contains('are you still');
  }

  /// True when the line is already a full customer turn and should not get
  /// stock emotion tails bolted on.
  static bool _isCompleteTurn(String t) {
    if (t.length >= 48) return true;
    if (t.contains('?') && t.length >= 28) return true;
    if (_isIdentityOrDataLine(t)) return true;
    if (_isClosingOrResolved(t)) return true;
    if (_alreadyHasUrgency(t)) return true;
    final l = t.toLowerCase();
    if (l.contains('please file') ||
        l.contains('file a request') ||
        l.contains('verify my') ||
        l.contains('what do you see') ||
        l.contains('on file')) {
      return true;
    }
    return false;
  }

  static String apply(String text, String emotion) {
    final t = text.trim();
    if (t.isEmpty) return t;
    final e = emotion.toLowerCase().trim();
    if (e.isEmpty || e == 'neutral' || e == 'curious') return t;

    // Complete scripted / off-track / identity lines keep their own wording.
    if (_isCompleteTurn(t)) return t;

    if (e.contains('paranoid') || e.contains('suspicious')) {
      if (!t.toLowerCase().contains('secure') && t.length < 100) {
        return '$t How do I know this is secure?';
      }
      return t;
    }

    if (e.contains('angry') || e.contains('upset')) {
      var out = t;
      // Short and medium lines: full caps + emphasis so chat shows heat.
      if (out.length <= 110 && out == out.toLowerCase()) {
        out = out.toUpperCase();
        if (!out.endsWith('!') && !out.endsWith('?')) out = '$out!';
        return out;
      }
      if (!out.contains('!') && !out.endsWith('?')) out = '$out!';
      // Longer scripted turns: punch the first clause for emphasis.
      if (out.length > 110 && !out.contains('!')) {
        final cut = out.indexOf('.');
        if (cut > 12 && cut < 80) {
          final head = out.substring(0, cut).toUpperCase();
          final tail = out.substring(cut);
          return '$head!$tail';
        }
      }
      return out.trim();
    }

    if (e.contains('disappoint')) {
      if (!t.contains('...') && t.length < 90) {
        return t.endsWith('.') ? '${t.substring(0, t.length - 1)}...' : '$t...';
      }
      return t;
    }

    if (e.contains('frustrat') ||
        e.contains('impatient') ||
        e.contains('annoy')) {
      // Short fragments only: light urgency, never stock dual-append tails.
      if (t.length < 40 && !t.contains('...')) {
        return t.endsWith('?') || t.endsWith('!') ? t : '$t...';
      }
      return t;
    }

    if (e.contains('sad')) {
      if (!t.toLowerCase().contains('please') && t.length < 80) {
        return t.endsWith('.')
            ? '${t.substring(0, t.length - 1)}, please...'
            : '$t, please...';
      }
      return t;
    }

    if (e.contains('worried') ||
        e.contains('anxious') ||
        e.contains('concern')) {
      if (!t.contains('?') && t.length < 80) {
        return t.endsWith('.')
            ? '${t.substring(0, t.length - 1)}?'
            : '$t?';
      }
      return t;
    }

    if (e.contains('confused')) {
      if (!t.contains('?')) {
        final base = t.endsWith('.') ? t.substring(0, t.length - 1) : t;
        return '$base?';
      }
      return t;
    }

    return t;
  }
}
