import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:trainixprogram/models/trainix_debug.dart';
import 'package:trainixprogram/models/training/script_personalization.dart';
import 'package:trainixprogram/models/training/training_categories.dart';
import 'package:trainixprogram/models/training/voice_line_player.dart';
import 'package:trainixprogram/screens/page/components/mini_training/combined_assessment_screen.dart';

class CategoryModule extends StatefulWidget {
  final Lesson lesson;
  final String categoryName;

  const CategoryModule({
    super.key,
    required this.lesson,
    required this.categoryName,
  });

  @override
  State<CategoryModule> createState() => _CategoryModuleState();
}

class _CategoryModuleState extends State<CategoryModule> {
  List<Widget> _lineWidgets(String trimmed) {
    if (trimmed.startsWith('### ')) {
      return [
        const Gap(6),
        Text(
          trimmed.substring(4),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            height: 1.35,
            color: Color(0xFF70BD8A),
          ),
        ),
        const Gap(6),
      ];
    }
    if (trimmed.startsWith('> ') ||
        trimmed.toLowerCase().startsWith('example:') ||
        trimmed.toLowerCase().startsWith('use case:')) {
      final body = trimmed.startsWith('> ') ? trimmed.substring(2) : trimmed;
      final speakText = body
          .replaceFirst(
            RegExp(r'^(example|use case):\s*', caseSensitive: false),
            '',
          )
          .trim();
      final emotion = widget.categoryName.toLowerCase().contains('empathy')
          ? 'empathetic'
          : widget.categoryName.toLowerCase().contains('escalat')
          ? 'firm'
          : 'professional';
      return [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 6, bottom: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF15201A),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF2E4A38)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                body,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: Color(0xFFD7E8DB),
                ),
              ),
              if (speakText.isNotEmpty) ...[
                const Gap(8),
                TextButton.icon(
                  onPressed: () {
                    VoiceLinePlayer.instance.playText(
                      speakText,
                      emotion: emotion,
                    );
                  },
                  icon: const Icon(Icons.volume_up_outlined, size: 16),
                  label: const Text('Hear line'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF70BD8A),
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 28),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ],
          ),
        ),
      ];
    }
    if (trimmed.startsWith('- ')) {
      return [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Text(
                  '•',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF70BD8A),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Gap(10),
              Expanded(
                child: Text(
                  trimmed.substring(2),
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: Color(0xFFE0E0E0),
                  ),
                ),
              ),
            ],
          ),
        ),
      ];
    }
    return [
      Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          trimmed,
          style: const TextStyle(
            fontSize: 15,
            height: 1.55,
            color: Color(0xFFD1D5DB),
          ),
        ),
      ),
    ];
  }

  List<Widget> buildContent(String content) {
    final lines = ScriptPersonalization.resolve(content).split('\n');
    final widgets = <Widget>[];
    String? sectionTitle;
    final sectionBody = <Widget>[];

    void flushSection() {
      if (sectionTitle == null && sectionBody.isEmpty) return;
      widgets.add(
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: const Color(0xFF151A21),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2A313A)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (sectionTitle != null) ...[
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 18,
                      decoration: BoxDecoration(
                        color: const Color(0xFF70BD8A),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const Gap(10),
                    Expanded(
                      child: Text(
                        sectionTitle!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const Gap(10),
              ],
              ...sectionBody,
            ],
          ),
        ),
      );
      sectionTitle = null;
      sectionBody.clear();
    }

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      if (trimmed.startsWith('## ')) {
        flushSection();
        sectionTitle = trimmed.substring(3);
        continue;
      }
      sectionBody.addAll(_lineWidgets(trimmed));
    }
    flushSection();
    if (widgets.isEmpty) return widgets;
    return [
      Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A2E24), Color(0xFF15201A)],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2E4A38)),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.lightbulb_outline, color: Color(0xFF70BD8A), size: 18),
            Gap(10),
            Expanded(
              child: Text(
                'Read each section, notice the examples, then take the assessment when you are ready. Small wording differences are fine in practice.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: Color(0xFFD7E8DB),
                ),
              ),
            ),
          ],
        ),
      ),
      ...widgets,
    ];
  }

  Lesson? _nextLesson() {
    final categoryData = trainingData[widget.categoryName];
    if (categoryData == null) return null;
    final lessons = categoryData.lessons;
    final idx = lessons.indexWhere((l) => l.id == widget.lesson.id);
    if (idx < 0 || idx >= lessons.length - 1) return null;
    final next = lessons[idx + 1];
    if (!next.isUnlocked && !widget.lesson.isCompleted) return null;
    return next;
  }

  Future<void> _openNextLesson() async {
    final next = _nextLesson();
    if (next == null) {
      Navigator.of(context).pop(true);
      return;
    }
    // Return next lesson to category screen so grid can refresh, then open it.
    Navigator.of(context).pop(next);
  }

  Future<void> _startAssessment() async {
    if (widget.lesson.assessments.isEmpty) return;

    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CombinedAssessmentScreen(
          categoryName: widget.categoryName,
          lesson: widget.lesson,
          items: widget.lesson.assessments,
        ),
      ),
    );

    if (result == true) {
      setState(() {});
    }
  }

  void _debugFinishLesson() {
    final categoryData = trainingData[widget.categoryName];
    if (categoryData == null) return;
    categoryData.markLessonCompleted(widget.lesson.id);
    for (final a in widget.lesson.assessments) {
      a.isCompleted = true;
      a.isPassed = true;
    }
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("DEBUG: Lesson assessment auto-finished")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDone = widget.lesson.isCompleted;
    final hasAssessment = widget.lesson.assessments.isNotEmpty;

    final score = widget.lesson.lastScorePercent;
    return Scaffold(
      backgroundColor: const Color(0xFF0F1419),
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: const Color(0xFF0F1419),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Lesson ${widget.lesson.order} · ${widget.lesson.title}',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF15201A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF2E4A38)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1F3A2A),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.menu_book_rounded,
                          color: Color(0xFF70BD8A),
                        ),
                      ),
                      const Gap(12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.lesson.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            const Gap(2),
                            Text(
                              isDone
                                  ? (score != null
                                        ? 'Completed · Last score $score%'
                                        : 'Completed')
                                  : 'Read the lesson, then take the assessment when ready.',
                              style: const TextStyle(
                                color: Color(0xFF9CA3AF),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(16),
                ...buildContent(widget.lesson.content),
                const Gap(28),
                if (hasAssessment) ...[
                  Align(
                    alignment: Alignment.center,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDone
                                ? const Color(0xFF374151)
                                : const Color(0xFF16A34A),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: isDone ? null : _startAssessment,
                          child: Text(
                            isDone
                                ? (score != null
                                      ? 'Assessment Passed ($score%)'
                                      : 'Assessment Passed')
                                : 'Start Assessment',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (isDone) ...[
                    const Gap(10),
                    Align(
                      alignment: Alignment.center,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: OutlinedButton(
                            onPressed: _startAssessment,
                            child: const Text('Retake Assessment (optional)'),
                          ),
                        ),
                      ),
                    ),
                    if (_nextLesson() != null) ...[
                      const Gap(10),
                      Align(
                        alignment: Alignment.center,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF16A34A),
                                foregroundColor: Colors.white,
                              ),
                              onPressed: _openNextLesson,
                              child: const Text('Continue to next lesson'),
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      const Gap(10),
                      Align(
                        alignment: Alignment.center,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => Navigator.of(context).maybePop(),
                              child: const Text('Back to category'),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                  if (TrainixDebug.unlocked) ...[
                    const Gap(12),
                    Align(
                      alignment: Alignment.center,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: SizedBox(
                          width: double.infinity,
                          height: 42,
                          child: OutlinedButton(
                            onPressed: isDone ? null : _debugFinishLesson,
                            child: const Text('DEBUG: Auto-finish this lesson'),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
                if (!hasAssessment)
                  const Text(
                    'No assessment available for this lesson yet.',
                    style: TextStyle(color: Colors.white54),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
