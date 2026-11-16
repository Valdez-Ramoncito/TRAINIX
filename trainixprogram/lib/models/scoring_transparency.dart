import 'package:flutter/material.dart';

/// Trainee-facing scoring transparency: levels, formula, and dimension criteria.
/// Matches the app instrument: start at 10, continuous deductions for observed gaps.
class ScoringTransparency {
  ScoringTransparency._();

  static const String formulaLine =
      'Overall = average of the 10 shared dimensions (each 0-10).';

  static const String methodLine =
      'Each dimension starts at 10. The evaluator subtracts points for every '
      'observed gap (partial or full). Scores are continuous, not limited to '
      'whole-number steps. Channel metrics (typing, fillers, pace) are tracked '
      'separately and do not change overall.';

  static const String whoScoresLine =
      'AI scores customer-facing turns. Trainer notes are labeled when present. '
      'Scenario setup is not scored as trainee performance.';

  static const String csatFormulaLine =
      'CSAT stars (1-5) = round((overall x 0.55 + soft x 0.45) / 10 x 5), '
      'where soft = (Empathy + Tone) / 2. If AHT is over the target, subtract 1 star '
      '(floor at 1). This is a Trainix customer-satisfaction model, not a TESDA unit.';

  static const int ahtTargetSeconds = 600;

  static const String ahtFormulaLine =
      'AHT (Average Handle Time) target = 600 seconds (10 minutes) per customer. '
      'Handle time is measured from customer start to resolution/close. '
      'Status is "AHT ok" when handle time is at or under 600s, and "AHT over" when above. '
      'Going over can lower CSAT by 1 star. The 600s target is a Trainix practice standard '
      'aligned with common contact-center handle-time coaching, not a named TESDA numeric rule.';

  static const List<ScoreLevel> levels = [
    ScoreLevel(
      id: 'excellent',
      label: 'Excellent',
      min: 9.0,
      max: 10.0,
      colorValue: 0xFF10B981,
      rangeLabel: '9-10',
      meaning: 'Full or near-full marks; criteria met with clear evidence.',
    ),
    ScoreLevel(
      id: 'proficient',
      label: 'Proficient',
      min: 7.0,
      max: 8.99,
      colorValue: 0xFF3B82F6,
      rangeLabel: '7-8',
      meaning: 'Solid performance; minor gaps only.',
    ),
    ScoreLevel(
      id: 'developing',
      label: 'Developing',
      min: 5.0,
      max: 6.99,
      colorValue: 0xFFF59E0B,
      rangeLabel: '5-6',
      meaning: 'Partial credit; important cues missing or weak.',
    ),
    ScoreLevel(
      id: 'needsWork',
      label: 'Needs work',
      min: 0.0,
      max: 4.99,
      colorValue: 0xFFEF4444,
      rangeLabel: '0-4',
      meaning: 'Limited evidence; priority practice area.',
    ),
  ];

  static ScoreLevel levelFor(double score) {
    final s = score.clamp(0.0, 10.0);
    for (final level in levels) {
      if (s >= level.min) return level;
    }
    return levels.last;
  }

  static double deductedFromTen(double score) {
    final s = score.clamp(0.0, 10.0);
    return (10.0 - s);
  }

  static const List<ScoringDimension> sharedDimensions = [
    ScoringDimension(
      key: 'openingSpiel',
      label: 'Opening Spiel',
      short: 'Greeting, agent ID, and offer of help in the first turns.',
      tesda: 'ICT313366',
      excellent: 'Clear greeting, name/role, and purpose stated early.',
      good: 'Greeting present; ID or purpose slightly soft.',
      developing: 'Generic open or missing one required piece.',
      needsWork: 'No real opening; jumps into the issue.',
      gapExamples:
          'Soft or delayed ID, thin purpose line, generic greeting. Larger cuts when ID is missing or the open is unprofessional.',
      deductionAnchors: [
        '-4: Generic or unprofessional greeting',
        '-3: Missing agent identification (name/role)',
        '-2: Missing offer of assistance / purpose',
        '-0.5 to -1.5: Soft, delayed, or incomplete ID (partial)',
        '-1: Greeting present but purpose delayed past the first turns (partial)',
      ],
      sourceNote:
          'TESDA Core Unit 2 ICT313366 (Perform Customer Service Delivery Processes; inbound opening spiel). Partial ranges follow BPO QA scorecard convention used in the evaluator prompt.',
    ),
    ScoringDimension(
      key: 'positiveScripting',
      label: 'Positive Scripting',
      short: 'Constructive language and alternatives instead of flat refusals.',
      tesda: 'ICT313367',
      excellent: 'Reframes limits and offers a workable next step.',
      good: 'Mostly constructive; one blunt line with recovery.',
      developing: 'Policy or refusal stated with weak alternative.',
      needsWork: 'Flat refusal with no path forward.',
      gapExamples:
          'Blunt refusal, policy stated without an alternative, weak recovery after a no.',
      deductionAnchors: [
        '-3: "I can\'t do that" / "that\'s policy" without an alternative in the same turn',
        '-2: Blunt rejection with no path forward',
        '-1 to -1.5: Weak recovery after a no, or alternative only after a hard refusal (partial)',
      ],
      sourceNote: 'TESDA Core Unit 3 ICT313367 (Engage Customers).',
    ),
    ScoringDimension(
      key: 'empathy',
      label: 'Empathy',
      short: 'Acknowledges the customer emotion before fixing.',
      tesda: 'ICT313367',
      excellent: 'Specific acknowledgment tied to what they said.',
      good: 'Clear acknowledgment; slightly generic.',
      developing: 'Canned or late acknowledgment.',
      needsWork: 'Emotion never acknowledged.',
      gapExamples:
          'Generic "I understand", late acknowledgment, or no recognition of frustration or urgency.',
      deductionAnchors: [
        '-5: Customer emotional state never acknowledged',
        '-3: Canned or copy-paste acknowledgment not specific to what the customer said',
        '-2: Acknowledgment only after troubleshooting already started (late)',
        '-1 to -1.5: Thin or generic acknowledgment (partial)',
      ],
      sourceNote: 'TESDA Core Unit 3 ICT313367 (Engage Customers / empathy).',
    ),
    ScoringDimension(
      key: 'activeListening',
      label: 'Active Listening',
      short: 'Reflects and uses information already given.',
      tesda: 'ICT313365',
      excellent: 'Confirms or restates the issue; no re-asks of known facts.',
      good: 'Mostly uses prior info; minor clarification only.',
      developing: 'Some re-asking of details already provided.',
      needsWork: 'Ignores or re-asks core facts from the customer.',
      gapExamples:
          'Re-asking name, account, or problem already stated; skipping a short restatement of the issue.',
      deductionAnchors: [
        '-5: Asks for information the customer already provided in their opening message',
        '-3: Re-asks a core fact (name, account, issue) already given later in the chat',
        '-2: Skips restating or confirming the issue when confirmation was needed',
        '-1: Minor unnecessary clarification of a detail already clear (partial)',
      ],
      sourceNote: 'TESDA Core Unit 1 ICT313365 (Communicate effectively).',
    ),
    ScoringDimension(
      key: 'problemIdentification',
      label: 'Problem Identification',
      short: 'Correct root cause and confirmation with the customer.',
      tesda: 'ICT313366',
      excellent: 'Accurate isolation and confirmed with the customer.',
      good: 'Correct direction; confirmation thin.',
      developing: 'Partial isolation or extra irrelevant steps.',
      needsWork: 'Misdiagnosis or wrong track.',
      gapExamples:
          'Thin confirmation, extra irrelevant checks, or wrong root cause.',
      deductionAnchors: [
        '-5: Misdiagnosis or wrong track',
        '-3: Unnecessary troubleshooting steps not relevant to the stated problem',
        '-2: Correct direction but never confirmed with the customer',
        '-1 to -1.5: Thin confirmation of the root cause (partial)',
      ],
      sourceNote: 'TESDA Core Unit 2 ICT313366 (Customer Service Delivery Processes).',
    ),
    ScoringDimension(
      key: 'solutionDelivery',
      label: 'Solution Delivery',
      short: 'Accurate, complete steps and ownership of the fix.',
      tesda: 'ICT313366',
      excellent: 'Correct, complete steps the customer can follow.',
      good: 'Mostly complete; one minor gap.',
      developing: 'Incomplete instructions.',
      needsWork: 'Wrong policy or incorrect facts.',
      gapExamples:
          'Missing a step, vague next action, or incorrect policy or fact.',
      deductionAnchors: [
        '-10: Incorrect policy or factual information',
        '-5: Incomplete set of instructions',
        '-3: Vague next action the customer cannot follow',
        '-1 to -2: Missing one non-critical step (partial)',
      ],
      sourceNote: 'TESDA Core Unit 2 ICT313366 (solution / resolution steps).',
    ),
    ScoringDimension(
      key: 'communicationClarity',
      label: 'Communication Clarity',
      short: 'Easy to follow; voice uses pronunciation clarity as the signal.',
      tesda: 'ICT313365',
      excellent: 'Clear structure and wording throughout.',
      good: 'Mostly clear; occasional dense phrasing.',
      developing: 'Hard to follow in places.',
      needsWork: 'Unclear or confusing delivery.',
      gapExamples:
          'Dense wording, unclear order of steps, or hard-to-follow delivery.',
      deductionAnchors: [
        '-3: Unformatted wall of text in a single message (chat)',
        '-2: Informal chat slang or abbreviations (u, r, plss)',
        '-2: Unclear order of steps that confuses the customer',
        '-1 to -1.5: Dense wording that is still readable but hard to scan (partial)',
      ],
      sourceNote:
          'TESDA Core Unit 1 ICT313365 (clarity, conciseness, coherence). Wall-of-text and slang anchors are Trainix chat operationalization of those 3 C\'s.',
    ),
    ScoringDimension(
      key: 'tone',
      label: 'Tone',
      short: 'Professional warmth and fit for the situation.',
      tesda: 'ICT313367',
      excellent: 'Warm, steady, and situation-appropriate.',
      good: 'Professional; warmth uneven.',
      developing: 'Flat or slightly mismatched tone.',
      needsWork: 'Cold, abrupt, or unprofessional tone.',
      gapExamples:
          'Flat or abrupt phrasing, mismatched warmth, or unprofessional wording.',
      deductionAnchors: [
        'Chat: score = (Empathy + Communication Clarity) / 2 (no separate vocal score)',
        'Voice -3 to -5: Unprofessional, rude, or hostile wording',
        'Voice -2 to -4: Flat, abrupt, or mismatched warmth',
        'Voice -1 to -2: Mild uneven warmth (partial)',
      ],
      sourceNote:
          'TESDA Core Unit 3 ICT313367. Chat tone is a derived proxy; voice tone is evaluated from delivery.',
    ),
    ScoringDimension(
      key: 'sectorKnowledge',
      label: 'Sector Knowledge',
      short: 'Accurate sector terms, policies, and procedures.',
      tesda: 'ICT313366',
      excellent: 'Correct terms and policy applied to this case.',
      good: 'Mostly accurate; minor imprecision.',
      developing: 'Vague or partially wrong sector detail.',
      needsWork: 'Wrong sector facts that affect the outcome.',
      gapExamples:
          'Vague policy language, imprecise sector terms, or incorrect procedure.',
      deductionAnchors: [
        '-5: Failed identity or security check when clearly required',
        '-3: Incorrect sector-specific terminology',
        '-2: Incorrect procedure that does not fully break the outcome',
        '-1 to -1.5: Vague policy language (partial)',
      ],
      sourceNote: 'TESDA Core Unit 2 ICT313366 (sector process and terms).',
    ),
    ScoringDimension(
      key: 'closingSpiel',
      label: 'Closing Spiel',
      short: 'Recap, offer of further help, and polite sign-off.',
      tesda: 'ICT313366',
      excellent: 'Resolution check, further-help offer, and clear close.',
      good: 'Close present; one piece light.',
      developing: 'Abrupt or incomplete close.',
      needsWork: 'No real closing sequence.',
      gapExamples:
          'Missing further-help offer, thin recap, or no clear sign-off.',
      deductionAnchors: [
        '-3: Missing offer of further help',
        '-3: Missing sign-off',
        '-2: No confirmation that the issue is resolved or next step is clear',
        '-1 to -1.5: Thin recap or abrupt close (partial)',
      ],
      sourceNote:
          'TESDA Core Unit 2 ICT313366 (inbound procedure requires a closing spiel).',
    ),
  ];

  static const List<ScoringDimension> channelDimensions = [
    ScoringDimension(
      key: 'confidence',
      label: 'Confidence',
      short: 'Steady, assured delivery without weak or apologetic hesitation.',
      tesda: 'ICT313365',
      excellent: 'Assured volume and pacing; no undercutting of the agent role.',
      good: 'Mostly steady; occasional soft hesitation.',
      developing: 'Frequent hesitation or trailing off.',
      needsWork: 'Frail, uncertain, or apologetic delivery throughout.',
      gapExamples:
          'Trailing volume, long uncertain pauses, or phrases that undercut authority.',
      deductionAnchors: [
        '-2 to -4: Frequent hesitation or frail volume',
        '-2 to -3: Undercutting phrases that signal low confidence',
        '-1 to -1.5: Occasional soft hesitation (partial)',
      ],
      sourceNote:
          'Voice delivery category under ICT313365. Separate from Tone warmth. '
          'Refuse wording alone is Positive Scripting, not automatic low Confidence.',
    ),
    ScoringDimension(
      key: 'spokenClarity',
      label: 'Spoken Clarity',
      short: 'Spoken message is easy to follow (structure and completeness).',
      tesda: 'ICT313365',
      excellent: 'Listener can track the point without rework.',
      good: 'Mostly clear; one dense stretch.',
      developing: 'Hard to follow in places.',
      needsWork: 'Spoken message is confusing even when words are audible.',
      gapExamples:
          'Incomplete sentences, jumbled order, or points the listener cannot track.',
      deductionAnchors: [
        '-2 to -3: Spoken message hard to follow',
        '-1 to -1.5: Dense stretch that is still recoverable (partial)',
      ],
      sourceNote:
          'Voice Spoken Clarity is separate from Pronunciation and Diction.',
    ),
    ScoringDimension(
      key: 'diction',
      label: 'Diction',
      short: 'Articulation quality: crisp vs mumbled endings and syllables.',
      tesda: 'ICT313365',
      excellent: 'Crisp articulation throughout.',
      good: 'Mostly clear; occasional soft endings.',
      developing: 'Mumbled stretches that slow understanding.',
      needsWork: 'Poor articulation that blocks understanding.',
      gapExamples: 'Swallowed endings, mumbled clauses, or slurred stretches.',
      deductionAnchors: [
        '-2: Mumbled or poorly articulated stretch',
        '-1 to -1.5: Soft endings that still allow understanding (partial)',
      ],
      sourceNote:
          'Voice Diction is separate from Pronunciation of specific words.',
    ),
    ScoringDimension(
      key: 'pronunciation',
      label: 'Pronunciation',
      short: 'Correct sound production of words so meaning is clear.',
      tesda: 'ICT313365',
      excellent: 'Words are pronounced correctly and are easy to recognize.',
      good: 'Minor mispronunciations that do not change meaning.',
      developing: 'Several mispronunciations that slow understanding.',
      needsWork: 'Severe mispronunciation that blocks meaning.',
      gapExamples:
          'Wrong stress or sound that changes meaning, or repeated mispronunciation of key terms.',
      deductionAnchors: [
        '-2: Severe mispronunciation that changes meaning or blocks understanding',
        '-1 to -1.5: Mild mispronunciation of a key term (partial)',
      ],
      sourceNote:
          'Voice Pronunciation is separate from Diction and Spoken Clarity.',
    ),
    ScoringDimension(
      key: 'paceAndSpeed',
      label: 'Pace & Speed',
      short: 'Speech rate in a healthy contact-center band.',
      tesda: 'ICT313365',
      excellent: 'Steady rate in the recommended band.',
      good: 'Slightly fast or slow but still clear.',
      developing: 'Noticeably rushed or slow.',
      needsWork: 'Extreme pace or unannounced long dead air.',
      gapExamples: 'Rushing, dragging, or long silent gaps without explanation.',
      deductionAnchors: [
        '-3: Rushing past a healthy baseline',
        '-3: Speaking noticeably slower than a healthy baseline',
        '-5: Unannounced dead air roughly over 10 seconds',
      ],
      sourceNote:
          'WPM bands are Trainix/BPO convention under ICT313365, not TESDA numbers.',
    ),
    ScoringDimension(
      key: 'fillerWordUsage',
      label: 'Filler Word Usage',
      short: 'Minimal verbal fillers (um, uh, like, you know).',
      tesda: 'ICT313365',
      excellent: 'Almost no fillers.',
      good: 'Occasional fillers that do not distract.',
      developing: 'Noticeable clusters of fillers.',
      needsWork: 'Fillers dominate turns and hurt clarity.',
      gapExamples: 'Repeated um/uh clusters or filler-heavy turns.',
      deductionAnchors: [
        '-2: Noticeable cluster of fillers',
        '-1 to -1.5: Occasional fillers (partial)',
      ],
      sourceNote: 'Voice filler scoring under ICT313365 clarity and conciseness.',
    ),
    ScoringDimension(
      key: 'grammar',
      label: 'Grammar',
      short: 'Sentence structure, agreement, and grammatical correctness.',
      tesda: 'ICT313365',
      excellent: 'Grammatically clean messages.',
      good: 'Minor grammar slips that do not change meaning.',
      developing: 'Several grammar errors that slow reading.',
      needsWork: 'Frequent grammar errors that harm professionalism.',
      gapExamples:
          'Broken agreement, incomplete sentence structure, or punctuation that changes meaning.',
      deductionAnchors: [
        '-2: Clear grammar error in a message',
        '-1 to -1.5: Mild structure issue (partial)',
      ],
      sourceNote:
          'Non-Voice Grammar is separate from keystroke accuracy and word choice. '
          'Missing apostrophes in dont/cant are a mild pattern (max -1), not -2 each. '
          'Refuse tone is Positive Scripting, not Grammar.',
    ),
    ScoringDimension(
      key: 'correctWordUse',
      label: 'Correct Word Use',
      short: 'Correct vocabulary and appropriate word selection.',
      tesda: 'ICT313365',
      excellent: 'Precise, appropriate terms throughout.',
      good: 'Mostly precise; one weak word choice.',
      developing: 'Several wrong or informal substitutions.',
      needsWork: 'Wrong words that change meaning or feel unprofessional.',
      gapExamples:
          'Wrong word that changes meaning, or slang used instead of the right term.',
      deductionAnchors: [
        '-2: Wrong or inappropriate word choice',
        '-1 to -1.5: Mild imprecise term (partial)',
      ],
      sourceNote:
          'Non-Voice Correct Word Use is separate from Grammar structure.',
    ),
    ScoringDimension(
      key: 'errorRateAccuracy',
      label: 'Error Rate & Accuracy',
      short: 'Keystroke precision from typing telemetry.',
      tesda: 'ICT311203',
      excellent: 'High keystroke accuracy at or above the practice threshold.',
      good: 'Solid accuracy with minor corrections.',
      developing: 'Accuracy under the practice threshold.',
      needsWork: 'Heavy correction pattern / low keystroke accuracy.',
      gapExamples: 'Accuracy under 95% practice threshold (Trainix convention).',
      deductionAnchors: [
        '-3: Keystroke accuracy under 95%',
      ],
      sourceNote:
          'Chat keystroke accuracy under ICT311203. Spelling and grammar are scored separately.',
    ),
    ScoringDimension(
      key: 'typingSpeed',
      label: 'Typing Speed',
      short: 'Typing pace for chat replies.',
      tesda: 'ICT311203',
      excellent: 'Steady pace at or above the practice baseline.',
      good: 'Near baseline with minor lag.',
      developing: 'Noticeably below baseline.',
      needsWork: 'Very slow typing that delays the customer.',
      gapExamples: 'WPM well below the practice baseline for chat work.',
      deductionAnchors: [
        '-2: WPM in the 25-29 band',
        '-5: WPM below 25',
      ],
      sourceNote:
          'Typing WPM bands are Trainix/BPO convention under ICT311203, not TESDA numbers.',
    ),
  ];

  static ScoringDimension? byLabel(String label) {
    for (final d in sharedDimensions) {
      if (d.label == label) return d;
    }
    for (final d in channelDimensions) {
      if (d.label == label) return d;
    }
    return null;
  }

  static IconData iconFor(String label) {
    switch (label) {
      case 'Opening Spiel':
        return Icons.waving_hand_outlined;
      case 'Positive Scripting':
        return Icons.thumb_up_alt_outlined;
      case 'Empathy':
        return Icons.favorite_outline;
      case 'Active Listening':
        return Icons.hearing_outlined;
      case 'Problem Identification':
        return Icons.search_outlined;
      case 'Solution Delivery':
        return Icons.handshake_outlined;
      case 'Communication Clarity':
      case 'Spoken Clarity':
        return Icons.chat_bubble_outline;
      case 'Tone':
        return Icons.record_voice_over_outlined;
      case 'Sector Knowledge':
        return Icons.menu_book_outlined;
      case 'Closing Spiel':
        return Icons.flag_outlined;
      case 'Confidence':
        return Icons.trending_up_rounded;
      case 'Diction':
        return Icons.record_voice_over_rounded;
      case 'Pronunciation':
        return Icons.mic_none_rounded;
      case 'Pace & Speed':
        return Icons.speed_rounded;
      case 'Filler Word Usage':
        return Icons.graphic_eq_rounded;
      case 'Grammar':
        return Icons.spellcheck_rounded;
      case 'Correct Word Use':
        return Icons.text_fields_rounded;
      case 'Error Rate & Accuracy':
        return Icons.fact_check_outlined;
      case 'Typing Speed':
        return Icons.keyboard_rounded;
      default:
        return Icons.analytics_outlined;
    }
  }
}

class ScoreLevel {
  final String id;
  final String label;
  final double min;
  final double max;
  final int colorValue;
  final String rangeLabel;
  final String meaning;

  const ScoreLevel({
    required this.id,
    required this.label,
    required this.min,
    required this.max,
    required this.colorValue,
    required this.rangeLabel,
    required this.meaning,
  });
}

class ScoringDimension {
  final String key;
  final String label;
  final String short;
  final String tesda;
  final String excellent;
  final String good;
  final String developing;
  final String needsWork;
  final String gapExamples;
  final List<String> deductionAnchors;
  final String sourceNote;

  const ScoringDimension({
    required this.key,
    required this.label,
    required this.short,
    required this.tesda,
    required this.excellent,
    required this.good,
    required this.developing,
    required this.needsWork,
    required this.gapExamples,
    this.deductionAnchors = const [],
    this.sourceNote = '',
  });

  String criterionForScore(double score) {
    if (score >= 9) return excellent;
    if (score >= 7) return good;
    if (score >= 5) return developing;
    return needsWork;
  }
}

class AttentivenessItem {
  final String label;
  final double weight;
  final bool earned;
  final String detail;

  const AttentivenessItem({
    required this.label,
    required this.weight,
    required this.earned,
    required this.detail,
  });
}

class AttentivenessBreakdown {
  final List<AttentivenessItem> items;
  final double percent;

  const AttentivenessBreakdown({
    required this.items,
    required this.percent,
  });

  double get earnedPoints =>
      items.fold(0.0, (s, i) => s + (i.earned ? i.weight : 0));

  double get maxPoints => items.fold(0.0, (s, i) => s + i.weight);

  static const String formulaLine =
      'Attentiveness % = (points earned / points available) x 100. '
      'Identity verification counts only when the case needs an account. '
      'Notes are a small bonus, not required.';
}
