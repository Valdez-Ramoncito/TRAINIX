import 'dart:math';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:trainixprogram/models/training/script_personalization.dart';
import 'package:trainixprogram/models/training/soft_text_match.dart';
import 'package:trainixprogram/models/training/training_categories.dart';
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
        }).toList()..shuffle(_random);
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
      if (isCorrect) {
        _correctCount++;
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
  }

  void _submitVoice(bool passed) {
    if (_lockedIn) return;
    setState(() {
      _lockedIn = true;
      _answeredCount++;
      if (passed) {
        _correctCount++;
      } else {
        _missed.add(
          MissedItem(
            prompt: _currentItem.title,
            yourAnswer: 'Spoken response did not meet script requirements',
            correctAnswer: _currentItem.voiceTargetScript ?? '',
            reason:
                'Say the required line clearly. Content Accuracy must pass the script checklist.',
          ),
        );
      }
    });
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
      final nextCategoryName = widget.isCategoryFinal
          ? _nextCategoryName()
          : null;
      return AssessmentResultsView(
        title: title,
        passed: _passed,
        correctCount: _correctCount,
        totalCount: _totalCount,
        missed: _missed,
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
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFF1A1A1A),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(8),
          child: LinearProgressIndicator(
            value: _progress,
            minHeight: 6,
            backgroundColor: const Color(0xFF2A2A2A),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
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
                Text(
                  "Progress: $_answeredCount / $_totalCount",
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white54,
                    letterSpacing: 0.3,
                  ),
                ),
                const Gap(16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF2C2C2C)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                      const Gap(6),
                      Text(
                        item.instructions,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white60,
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
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _lockInQuiz,
                      child: const Text("Confirm Answer"),
                    ),
                  ),
                if (_lockedIn)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _next,
                      child: Text(
                        _itemIndex == _items.length - 1 &&
                                (item.type != AssessmentType.quiz ||
                                    _questionIndex == quizQuestions.length - 1)
                            ? "See Results"
                            : "Next",
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
