import 'dart:math';
import 'package:flutter/material.dart';
import 'package:trainixprogram/components/app_colors.dart';
import 'package:gap/gap.dart';
import 'package:trainixprogram/models/scoring_transparency.dart';
import 'package:trainixprogram/models/training/script_personalization.dart';
import 'package:trainixprogram/models/training/soft_text_match.dart';
import 'package:trainixprogram/models/training/training_categories.dart';
import 'package:trainixprogram/models/training/voice_scoring/voice_score_result.dart';
import 'package:trainixprogram/screens/page/components/mini_training/combined_assessment/assessment_models.dart';
import 'package:trainixprogram/screens/page/components/mini_training/combined_assessment/assessment_quiz_view.dart';
import 'package:trainixprogram/screens/page/components/mini_training/combined_assessment/assessment_results_view.dart';
import 'package:trainixprogram/screens/page/components/mini_training/combined_assessment/assessment_typing_view.dart';
import 'package:trainixprogram/screens/page/components/mini_training/combined_assessment/assessment_voice_view.dart';

class CombinedAssessmentScreen extends StatefulWidget {
  final String categoryName;
  final Lesson lesson;
  final bool isCategoryFinal;
  final List<Assessment> items;

  const CombinedAssessmentScreen({
    super.key,
    required this.categoryName,
    required this.lesson,
    required this.items,
    this.isCategoryFinal = false,
  });

  @override
  State<CombinedAssessmentScreen> createState() =>
      _CombinedAssessmentScreenState();
}

class _CombinedAssessmentScreenState extends State<CombinedAssessmentScreen> {
  final _random = Random();
  late List<Assessment> _items;
  final Map<String, List<ShuffledQuestion>> _shuffledQuizzes = {};
  final List<MissedItem> _missed = [];
  final List<AssessmentItemResult> _results = [];
  final Map<String, int> _itemEarned = {};
  final Map<String, List<int?>> _quizPicks = {};

  int _itemIndex = 0;
  int _questionIndex = 0;
  int _correctCount = 0;
  int _totalCount = 0;
  int _answeredCount = 0;
  bool _finished = false;
  bool _passed = false;
  int? _selectedOption;
  bool _lockedIn = false;
  final TextEditingController _typingController = TextEditingController();
  String? _typingFeedback;
  String? _immediateFeedback;

  @override
  void initState() {
    super.initState();
    _prepareSession();
  }

  @override
  void dispose() {
    _typingController.dispose();
    super.dispose();
  }

  void _prepareSession() {
    _items = List<Assessment>.from(widget.items)..shuffle(_random);
    _shuffledQuizzes.clear();
    _missed.clear();
    _results.clear();
    _itemEarned.clear();
    _quizPicks.clear();

    for (final item in _items) {
      if (item.type == AssessmentType.quiz && item.quizQuestions != null) {
        final shuffledQs = item.quizQuestions!.map((q) {
          final indices = List<int>.generate(q.options.length, (i) => i)
            ..shuffle(_random);
          final newOptions = indices.map((i) => q.options[i]).toList();
          final newCorrect = indices.indexOf(q.correctIndex);
          return ShuffledQuestion(
            question: q.question,
            options: newOptions,
            correctIndex: newCorrect,
            explanation: q.explanation,
          );
        }).toList()
          ..shuffle(_random);
        _shuffledQuizzes[item.id] = shuffledQs;
      }
    }

    _totalCount = _countTotalItems();
    _itemIndex = 0;
    _questionIndex = 0;
    _correctCount = 0;
    _answeredCount = 0;
    _finished = false;
    _passed = false;
    _selectedOption = null;
    _lockedIn = false;
    _typingController.clear();
    _typingFeedback = null;
    _immediateFeedback = null;
  }

  void _recordQuizResult(Assessment item) {
    final questions = _shuffledQuizzes[item.id] ?? [];
    final picks = _quizPicks[item.id] ?? const <int?>[];
    final earned = _itemEarned[item.id] ?? 0;
    final evidence = <String>[];
    final notes = <String>[];
    for (var i = 0; i < questions.length; i++) {
      final q = questions[i];
      final pick = i < picks.length ? picks[i] : null;
      final pickedText = pick == null ? '(not answered)' : q.options[pick];
      final correctText = q.options[q.correctIndex];
      evidence.add(
        'Q${i + 1}: ${q.question} Your answer: "$pickedText". '
        'Correct answer: "$correctText".',
      );
      if (pick != q.correctIndex) {
        final reason =
            (q.explanation != null && q.explanation!.trim().isNotEmpty)
                ? q.explanation!
                : 'The correct answer is: $correctText';
        notes.add('Q${i + 1}: $reason');
      }
    }
    final ratio = questions.isEmpty ? 0.0 : earned / questions.length;
    _results.add(
      AssessmentItemResult(
        title: item.title,
        kind: AssessmentItemKind.quiz,
        passed: ratio >= 0.75,
        scoreText: '$earned / ${questions.length}',
        earned: earned,
        available: questions.length,
        parts: [
          'Correct answers: $earned',
          'Questions in this item: ${questions.length}',
          'Item score: ${(ratio * 100).round()}%',
        ],
        basis:
            '${ScoringTransparency.quizInstrumentLine} ${ScoringTransparency.quizDeductionLine}',
        evidence: evidence,
        notes: notes,
      ),
    );
  }

  int _countTotalItems() {
    int count = 0;
    for (final item in _items) {
      if (item.type == AssessmentType.quiz) {
        count += _shuffledQuizzes[item.id]?.length ?? 0;
      } else {
        count += 1;
      }
    }
    return count;
  }

  Assessment get _currentItem => _items[_itemIndex];

  double get _progress {
    if (_totalCount == 0) return 0;
    return _answeredCount / _totalCount;
  }

  void _selectOption(int index) {
    if (_lockedIn) return;
    setState(() {
      _selectedOption = index;
    });
  }

  void _lockInQuiz() {
    if (_selectedOption == null || _lockedIn) return;
    final questions = _shuffledQuizzes[_currentItem.id] ?? [];
    if (_questionIndex >= questions.length) return;

    final q = questions[_questionIndex];
    final isCorrect = _selectedOption == q.correctIndex;
    final reason = (q.explanation != null && q.explanation!.trim().isNotEmpty)
        ? q.explanation!
        : "The correct answer is: ${q.options[q.correctIndex]}";

    setState(() {
      _lockedIn = true;
      _answeredCount++;
      final picks = _quizPicks[_currentItem.id] ??=
          List<int?>.filled(questions.length, null);
      picks[_questionIndex] = _selectedOption;
      if (isCorrect) {
        _correctCount++;
        _itemEarned[_currentItem.id] = (_itemEarned[_currentItem.id] ?? 0) + 1;
        _immediateFeedback = null;
      } else {
        _immediateFeedback = reason;
        _missed.add(
          MissedItem(
            prompt: q.question,
            yourAnswer: q.options[_selectedOption!],
            correctAnswer: q.options[q.correctIndex],
            reason: reason,
          ),
        );
      }
    });
  }

  void _submitTyping() {
    if (_lockedIn) return;
    final target = ScriptPersonalization.resolve(
      (_currentItem.typingTargetText ?? '').trim(),
    );
    final input = _typingController.text.trim();
    final isCorrect = SoftTextMatch.typingMatches(input, target);

    setState(() {
      _lockedIn = true;
      _answeredCount++;
      if (isCorrect) {
        _correctCount++;
        _typingFeedback = 'Correct';
      } else {
        _typingFeedback = 'Incorrect';
        _missed.add(
          MissedItem(
            prompt: _currentItem.title,
            yourAnswer: input.isEmpty ? '(blank)' : input,
            correctAnswer: target,
            reason:
                'Cover the same meaning as the target. Exact wording and punctuation are not required.',
          ),
        );
      }
    });
    _results.add(
      AssessmentItemResult(
        title: _currentItem.title,
        kind: AssessmentItemKind.typing,
        passed: isCorrect,
        scoreText: isCorrect ? '1 / 1' : '0 / 1',
        earned: isCorrect ? 1 : 0,
        available: 1,
        parts: [
          'Meaning match: ${isCorrect ? 'matched' : 'not matched'}',
          'Item score: ${isCorrect ? 100 : 0}%',
        ],
        basis: ScoringTransparency.typingInstrumentLine,
        evidence: [
          'Target reply: "$target"',
          'You typed: "${input.isEmpty ? '(blank)' : input}"',
        ],
        notes: isCorrect
            ? const []
            : const [
                'The reply has to carry the same meaning as the target. Wording, spacing, and punctuation can differ.',
              ],
      ),
    );
  }

  void _submitVoice(VoiceScoreResult result) {
    if (_lockedIn) return;
    setState(() {
      _lockedIn = true;
      _answeredCount++;
      if (result.passed) {
        _correctCount++;
      } else {
        _missed.add(
          MissedItem(
            prompt: _currentItem.title,
            yourAnswer:
                result.criticalFail && result.criticalFailReason.isNotEmpty
                    ? result.criticalFailReason
                    : 'Spoken response did not meet script requirements',
            correctAnswer: _currentItem.voiceTargetScript ?? '',
            reason:
                'Say the required line clearly. Content Accuracy must pass the script checklist.',
          ),
        );
      }
    });
    _results.add(_buildVoiceResult(_currentItem, result));
  }

  AssessmentItemResult _buildVoiceResult(
    Assessment item,
    VoiceScoreResult result,
  ) {
    final target = ScriptPersonalization.resolve(item.voiceTargetScript ?? '');
    final targetLower = target.toLowerCase();
    final isOpening = targetLower.contains('thank you for calling') ||
        targetLower.contains('how may i help') ||
        targetLower.contains('how can i help');
    final isClosing = targetLower.contains('anything else') ||
        (targetLower.contains('thank you for calling') &&
            targetLower.contains('good day')) ||
        targetLower.contains('have a good');
    final contentLine = isOpening
        ? ScoringTransparency.openingContentLine
        : (isClosing
            ? ScoringTransparency.closingContentLine
            : ScoringTransparency.scriptContentLine);
    final basis = result.deliveryEvaluated
        ? '${ScoringTransparency.voiceInstrumentLine} $contentLine '
            '${ScoringTransparency.deliveryRubricLine}'
        : '${ScoringTransparency.voiceInstrumentLine} $contentLine';

    final parts = <String>[
      'Content Accuracy: ${result.contentScore} / 50',
      if (result.deliveryEvaluated)
        'Delivery Quality: ${result.deliveryScore} / 50'
      else
        'Delivery Quality: not scored for this item',
      if (result.deliveryEvaluated) 'Clarity: ${result.clarityScore} / 15',
      if (result.deliveryEvaluated) 'Pace: ${result.paceScore} / 10',
      if (result.deliveryEvaluated) 'Tone: ${result.toneScore} / 15',
      if (result.deliveryEvaluated)
        'Confidence: ${result.confidenceScore} / 10',
      'Total: ${result.totalScore} / 100',
    ];

    final evidence = <String>[
      if (result.transcript.trim().isNotEmpty)
        'What we heard: "${result.transcript.trim()}"',
      if (target.isNotEmpty) 'Target line: "$target"',
      if (result.criticalFail && result.criticalFailReason.isNotEmpty)
        'Automatic fail: ${result.criticalFailReason}',
    ];

    return AssessmentItemResult(
      title: item.title,
      kind: AssessmentItemKind.voice,
      passed: result.passed,
      scoreText: '${result.totalScore} / 100',
      earned: result.totalScore,
      available: 100,
      parts: parts,
      basis: basis,
      evidence: evidence,
      notes: [
        ...result.contentNotes,
        ...result.deliveryNotes,
        if (!result.deliveryEvaluated) ScoringTransparency.pendingDeliveryLine,
      ],
    );
  }

  void _next() {
    if (!_lockedIn) return;

    final item = _currentItem;

    if (item.type == AssessmentType.quiz) {
      final questions = _shuffledQuizzes[item.id] ?? [];
      if (_questionIndex < questions.length - 1) {
        setState(() {
          _questionIndex++;
          _selectedOption = null;
          _lockedIn = false;
          _immediateFeedback = null;
        });
        return;
      }
      _recordQuizResult(item);
    }

    if (_itemIndex < _items.length - 1) {
      setState(() {
        _itemIndex++;
        _questionIndex = 0;
        _selectedOption = null;
        _lockedIn = false;
        _typingController.clear();
        _typingFeedback = null;
        _immediateFeedback = null;
      });
      return;
    }

    final ratio = _totalCount > 0 ? _correctCount / _totalCount : 0.0;
    final passed = ratio >= 0.75;
    final percent = (ratio * 100).round();
    if (!widget.isCategoryFinal) {
      widget.lesson.lastScorePercent = percent;
    }
    setState(() {
      _finished = true;
      _passed = passed;
    });

    if (passed) {
      _applyPass();
    }
  }

  String? _nextCategoryName() {
    final currentIndex = categories.indexWhere(
      (c) => c.name == widget.categoryName,
    );
    if (currentIndex == -1 || currentIndex >= categories.length - 1) {
      return null;
    }
    return categories[currentIndex + 1].name;
  }

  void _applyPass() {
    final categoryData = trainingData[widget.categoryName];
    if (categoryData == null) return;

    if (widget.isCategoryFinal) {
      categoryData.markFinalTestPassed();

      final categoryListItem = categories.firstWhere(
        (c) => c.name == widget.categoryName,
        orElse: () => categories.first,
      );
      categoryListItem.isComplete = true;
      categoryListItem.isNext = false;

      final currentIndex = categories.indexWhere(
        (c) => c.name == widget.categoryName,
      );
      if (currentIndex != -1 && currentIndex < categories.length - 1) {
        categories[currentIndex + 1].isNext = true;
      }

      MiniTrainingProgress.refreshGlobalProgress();
    } else {
      categoryData.markLessonCompleted(widget.lesson.id);
      for (final a in widget.lesson.assessments) {
        a.isCompleted = true;
        a.isPassed = true;
      }
    }
  }

  void _retry() {
    setState(() {
      _prepareSession();
    });
  }

  IconData _itemIcon(AssessmentType type) {
    switch (type) {
      case AssessmentType.quiz:
        return Icons.quiz_outlined;
      case AssessmentType.typing:
        return Icons.keyboard_rounded;
      case AssessmentType.voice:
        return Icons.mic_none_rounded;
      case AssessmentType.finalTest:
        return Icons.assignment_turned_in_outlined;
    }
  }

  bool _useDeliveryScoring() {
    if (widget.isCategoryFinal) return true;
    if (widget.categoryName == 'Grand Final') return true;
    const deliveryCategories = {
      'Pace & Speed',
      'Pronunciation & Clarity',
      'Tone & Inflection',
      'Filler Word Usage',
    };
    return deliveryCategories.contains(widget.categoryName);
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isCategoryFinal
        ? "${widget.categoryName} - Final Assessment"
        : "Assessment - ${widget.lesson.title}";

    if (_items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: const Center(child: Text("No assessment items available.")),
      );
    }

    if (_finished) {
      final nextCategoryName =
          widget.isCategoryFinal ? _nextCategoryName() : null;
      return AssessmentResultsView(
        title: title,
        passed: _passed,
        correctCount: _correctCount,
        totalCount: _totalCount,
        missed: _missed,
        results: _results,
        onRetry: _retry,
        continueLabel: nextCategoryName != null
            ? 'Continue to $nextCategoryName'
            : (widget.isCategoryFinal ? 'Back to categories' : 'Continue'),
        onContinue: () {
          if (nextCategoryName != null) {
            Navigator.of(context).pop({'nextCategory': nextCategoryName});
            return;
          }
          Navigator.of(context).pop(true);
        },
      );
    }

    final item = _currentItem;
    final quizQuestions = _shuffledQuizzes[item.id] ?? [];

    return Scaffold(
      backgroundColor: AppColors.inputFill(context),
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.elevated(context),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(8),
          child: LinearProgressIndicator(
            value: _progress,
            minHeight: 6,
            backgroundColor: AppColors.border(context),
            valueColor:
                AlwaysStoppedAnimation<Color>(AppColors.primary(context)),
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.track_changes_rounded,
                      size: 15,
                      color: AppColors.textMuted(context),
                    ),
                    const Gap(6),
                    Text(
                      "Progress: $_answeredCount / $_totalCount",
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted(context),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                const Gap(16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.card(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border(context)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryText()
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _itemIcon(item.type),
                              size: 16,
                              color: AppColors.secondaryText(),
                            ),
                          ),
                          const Gap(10),
                          Expanded(
                            child: Text(
                              item.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Gap(6),
                      Text(
                        item.instructions,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary(context),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(24),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (item.type == AssessmentType.quiz &&
                            quizQuestions.isNotEmpty)
                          AssessmentQuizView(
                            question: quizQuestions[_questionIndex],
                            questionNumber: _questionIndex + 1,
                            questionTotal: quizQuestions.length,
                            selectedOption: _selectedOption,
                            lockedIn: _lockedIn,
                            immediateFeedback: _immediateFeedback,
                            onSelectOption: _selectOption,
                          ),
                        if (item.type == AssessmentType.typing)
                          AssessmentTypingView(
                            item: item,
                            controller: _typingController,
                            lockedIn: _lockedIn,
                            typingFeedback: _typingFeedback,
                            onCheck: _submitTyping,
                          ),
                        if (item.type == AssessmentType.voice)
                          AssessmentVoiceView(
                            item: item,
                            lockedIn: _lockedIn,
                            useDeliveryScoring: _useDeliveryScoring(),
                            onCompleted: _submitVoice,
                          ),
                      ],
                    ),
                  ),
                ),
                const Gap(16),
                if (!_lockedIn &&
                    item.type == AssessmentType.quiz &&
                    _selectedOption != null)
                  Align(
                    alignment: Alignment.center,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary(context),
                            foregroundColor: AppColors.onPrimary(context),
                          ),
                          onPressed: _lockInQuiz,
                          child: const Text("Confirm Answer"),
                        ),
                      ),
                    ),
                  ),
                if (_lockedIn)
                  Align(
                    alignment: Alignment.center,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary(context),
                            foregroundColor: AppColors.onPrimary(context),
                          ),
                          onPressed: _next,
                          child: Text(
                            _itemIndex == _items.length - 1 &&
                                    (item.type != AssessmentType.quiz ||
                                        _questionIndex ==
                                            quizQuestions.length - 1)
                                ? "See Results"
                                : "Next",
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
