import 'dart:async';

import 'package:flutter/material.dart';
import 'package:trainixprogram/components/app_colors.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:trainixprogram/models/training/typing/typing_passage.dart';
import 'package:trainixprogram/models/training/typing/typing_passage_catalog.dart';
import 'package:trainixprogram/models/training/typing/typing_practice_store.dart';
import 'package:trainixprogram/models/training/typing/typing_result.dart';

class TypingTestScreen extends StatefulWidget {
  final int durationSeconds;
  final TypingPack pack;
  final bool noBackspace;

  const TypingTestScreen({
    super.key,
    required this.durationSeconds,
    required this.pack,
    this.noBackspace = false,
  });

  @override
  State<TypingTestScreen> createState() => _TypingTestScreenState();
}

class _TypingTestScreenState extends State<TypingTestScreen> {
  static Color get _green => AppColors.primaryText();
  static Color get _red => AppColors.errorText();

  final FocusNode _focusNode = FocusNode();
  final TextEditingController _controller = TextEditingController();

  late List<TypingPassage> _queue;
  int _passageIndex = 0;
  String _target = '';
  String _typed = '';

  int _correctChars = 0;
  int _incorrectChars = 0;
  int _totalKeystrokes = 0;
  int _passagesCompleted = 0;

  bool _started = false;
  bool _finished = false;
  int _remainingSeconds = 0;
  Timer? _timer;
  DateTime? _startedAt;
  TypingResult? _result;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.durationSeconds;
    _queue = TypingPassageCatalog.shuffledForPack(widget.pack);
    if (_queue.isEmpty) {
      _queue = List<TypingPassage>.from(TypingPassageCatalog.general);
    }
    _loadPassage(0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _loadPassage(int index) {
    if (_queue.isEmpty) return;
    _passageIndex = index % _queue.length;
    _target = _queue[_passageIndex].text;
    _typed = '';
    _controller.clear();
  }

  void _startTimerIfNeeded() {
    if (_started || _finished) return;
    _started = true;
    _startedAt = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _finished) return;
      setState(() {
        _remainingSeconds -= 1;
        if (_remainingSeconds <= 0) {
          _remainingSeconds = 0;
          _finish(completedByTime: true);
        }
      });
    });
  }

  void _finish({required bool completedByTime}) {
    if (_finished) return;
    _timer?.cancel();
    _finished = true;

    final elapsed = widget.durationSeconds - _remainingSeconds;
    final durationUsed =
        completedByTime ? widget.durationSeconds : (elapsed <= 0 ? 1 : elapsed);

    final result = TypingResult(
      durationSeconds: durationUsed,
      pack: widget.pack,
      correctChars: _correctChars,
      incorrectChars: _incorrectChars,
      totalKeystrokes: _totalKeystrokes,
      passagesCompleted: _passagesCompleted,
      finishedAt: DateTime.now(),
      completedByTime: completedByTime,
      noBackspace: widget.noBackspace,
    );
    TypingPracticeStore.record(result);
    setState(() => _result = result);
  }

  void _onTextChanged(String value) {
    if (_finished) return;

    if (widget.noBackspace && value.length < _typed.length) {
      _controller.value = TextEditingValue(
        text: _typed,
        selection: TextSelection.collapsed(offset: _typed.length),
      );
      return;
    }

    _startTimerIfNeeded();

    if (value.length < _typed.length) {
      setState(() => _typed = value);
      return;
    }

    final prevLen = _typed.length;
    final added = value.substring(prevLen);
    var correct = _correctChars;
    var incorrect = _incorrectChars;
    var keystrokes = _totalKeystrokes;
    var typed = _typed;

    for (var i = 0; i < added.length; i++) {
      final pos = typed.length;
      final ch = added[i];
      keystrokes += 1;
      if (pos < _target.length && ch == _target[pos]) {
        correct += 1;
        typed += ch;
      } else if (pos < _target.length) {
        incorrect += 1;
        typed += ch;
      } else {
        incorrect += 1;
        typed += ch;
      }
    }

    _correctChars = correct;
    _incorrectChars = incorrect;
    _totalKeystrokes = keystrokes;
    _typed = typed;

    if (_typed.length >= _target.length) {
      _passagesCompleted += 1;
      _loadPassage(_passageIndex + 1);
    }

    setState(() {});
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (_finished) return KeyEventResult.ignored;
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).maybePop();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  double get _liveWpm {
    if (!_started || _startedAt == null) return 0;
    final elapsedMs =
        DateTime.now().difference(_startedAt!).inMilliseconds.clamp(1, 1 << 30);
    final minutes = elapsedMs / 60000.0;
    return (_correctChars / 5.0) / minutes;
  }

  double get _liveAccuracy {
    if (_totalKeystrokes <= 0) return 100;
    final ok = _totalKeystrokes - _incorrectChars;
    if (ok <= 0) return 0;
    return (ok / _totalKeystrokes) * 100;
  }

  @override
  Widget build(BuildContext context) {
    if (_finished && _result != null) {
      return _ResultBody(
        result: _result!,
        onRetry: () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => TypingTestScreen(
                durationSeconds: widget.durationSeconds,
                pack: widget.pack,
                noBackspace: widget.noBackspace,
              ),
            ),
          );
        },
        onDone: () => Navigator.of(context).pop(true),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      body: Focus(
        focusNode: _focusNode,
        onKeyEvent: _onKey,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TopBar(
                remainingSeconds: _remainingSeconds,
                durationSeconds: widget.durationSeconds,
                wpm: _liveWpm,
                accuracy: _liveAccuracy,
                pack: widget.pack,
                noBackspace: widget.noBackspace,
                onExit: () => Navigator.of(context).maybePop(),
              ),
              const Gap(28),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 920),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: AppColors.card(context),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: AppColors.borderIdle(context)),
                          ),
                          child: _PassageHighlight(
                            target: _target,
                            typed: _typed,
                          ),
                        ),
                        const Gap(20),
                        TextField(
                          controller: _controller,
                          autofocus: true,
                          enabled: !_finished,
                          maxLines: 3,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            color: AppColors.textPrimary(context),
                          ),
                          cursorColor: _green,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppColors.card(context),
                            hintText: _started
                                ? 'Keep typing...'
                                : 'Start typing to begin the timer',
                            hintStyle:
                                TextStyle(color: AppColors.textMuted(context)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: AppColors.borderIdle(context)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: AppColors.borderIdle(context)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: _green),
                            ),
                          ),
                          onChanged: _onTextChanged,
                        ),
                        const Gap(14),
                        Text(
                          widget.noBackspace
                              ? 'No-backspace mode is on. Escape to exit.'
                              : 'Timer starts on first key. Escape to exit.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  Text(
                    'Passage ${_passagesCompleted + 1}'
                    '${_queue.isNotEmpty ? ' · ${_queue[_passageIndex].label}' : ''}',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textMuted(context)),
                  ),
                  const Spacer(),
                  Text(
                    '$_passagesCompleted completed · $_totalKeystrokes keys',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textMuted(context)),
                  ),
                  const SizedBox(width: 64),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final int remainingSeconds;
  final int durationSeconds;
  final double wpm;
  final double accuracy;
  final TypingPack pack;
  final bool noBackspace;
  final VoidCallback onExit;

  const _TopBar({
    required this.remainingSeconds,
    required this.durationSeconds,
    required this.wpm,
    required this.accuracy,
    required this.pack,
    required this.noBackspace,
    required this.onExit,
  });

  String get _packLabel {
    switch (pack) {
      case TypingPack.general:
        return 'General';
      case TypingPack.scripts:
        return 'Scripts';
      case TypingPack.chat:
        return 'Chat';
    }
  }

  @override
  Widget build(BuildContext context) {
    final mm = (remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final ss = (remainingSeconds % 60).toString().padLeft(2, '0');
    final urgent = remainingSeconds <= 5 && remainingSeconds > 0;

    return Row(
      children: [
        TextButton.icon(
          onPressed: onExit,
          icon: Icon(Icons.close,
              size: 18, color: AppColors.textSecondary(context)),
          label: Text('Exit',
              style: TextStyle(color: AppColors.textSecondary(context))),
        ),
        const Gap(16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.elevated(context),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border(context)),
          ),
          child: Text(
            '$_packLabel · ${durationSeconds}s'
            '${noBackspace ? ' · No BS' : ''}',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted(context)),
          ),
        ),
        const Spacer(),
        _StatChip(
          label: 'Time',
          value: '$mm:$ss',
          icon: Icons.timer_outlined,
          emphasize: urgent,
        ),
        const Gap(12),
        _StatChip(
          label: 'WPM',
          value: wpm.toStringAsFixed(0),
          icon: Icons.speed_rounded,
        ),
        const Gap(12),
        _StatChip(
          label: 'Accuracy',
          value: '${accuracy.round()}%',
          icon: Icons.check_circle_outline,
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final bool emphasize;

  const _StatChip({
    required this.label,
    required this.value,
    this.icon,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    final icon = this.icon;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.elevated(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: emphasize ? AppColors.errorText() : AppColors.border(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 13,
                  color: emphasize
                      ? AppColors.errorText()
                      : AppColors.textMuted(context),
                ),
                const Gap(4),
              ],
              Text(
                label,
                style: TextStyle(
                    fontSize: 11, color: AppColors.textMuted(context)),
              ),
            ],
          ),
          const Gap(2),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: emphasize
                  ? AppColors.errorText()
                  : AppColors.textPrimary(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _PassageHighlight extends StatelessWidget {
  final String target;
  final String typed;

  const _PassageHighlight({required this.target, required this.typed});

  @override
  Widget build(BuildContext context) {
    final spans = <TextSpan>[];
    final maxLen = typed.length > target.length ? typed.length : target.length;

    for (var i = 0; i < maxLen; i++) {
      if (i < typed.length && i < target.length) {
        final ok = typed[i] == target[i];
        spans.add(
          TextSpan(
            text: target[i],
            style: TextStyle(
              color: ok ? AppColors.primaryText() : AppColors.errorText(),
              backgroundColor:
                  ok ? null : AppColors.errorText().withValues(alpha: 0.18),
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      } else if (i < typed.length && i >= target.length) {
        spans.add(
          TextSpan(
            text: typed[i],
            style: TextStyle(
              color: AppColors.errorText(),
              backgroundColor: AppColors.errorText().withValues(alpha: 0.18),
            ),
          ),
        );
      } else if (i == typed.length && i < target.length) {
        spans.add(
          TextSpan(
            text: target[i],
            style: TextStyle(
              color: AppColors.textPrimary(context),
              decoration: TextDecoration.underline,
              decorationColor: AppColors.primaryText(),
            ),
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: target[i],
            style: TextStyle(color: AppColors.textMuted(context)),
          ),
        );
      }
    }

    if (target.isEmpty) {
      spans.add(
        TextSpan(
          text: 'No passage loaded.',
          style: TextStyle(color: AppColors.textMuted(context)),
        ),
      );
    }

    return Text.rich(
      TextSpan(children: spans),
      style: const TextStyle(
        fontSize: 20,
        height: 1.55,
        letterSpacing: 0.2,
      ),
    );
  }
}

class _ResultBody extends StatelessWidget {
  final TypingResult result;
  final VoidCallback onRetry;
  final VoidCallback onDone;

  const _ResultBody({
    required this.result,
    required this.onRetry,
    required this.onDone,
  });

  String get _packLabel {
    switch (result.pack) {
      case TypingPack.general:
        return 'General';
      case TypingPack.scripts:
        return 'Scripts';
      case TypingPack.chat:
        return 'Chat';
    }
  }

  @override
  Widget build(BuildContext context) {
    final best = TypingPracticeStore.bestFor(
      durationSeconds: result.durationSeconds,
      pack: result.pack,
    );
    final isNewBest = best != null &&
        best.finishedAt == result.finishedAt &&
        best.netWpm == result.netWpm;

    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.elevated(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Run complete',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Gap(6),
                Text(
                  '$_packLabel · ${result.durationSeconds}s'
                  '${result.noBackspace ? ' · No backspace' : ''}',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted(context),
                  ),
                ),
                if (isNewBest) ...[
                  const Gap(12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryText().withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primaryText().withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      'Personal best for this mode',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primaryText(),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                const Gap(28),
                Row(
                  children: [
                    Expanded(
                      child: _ResultMetric(
                        label: 'Net WPM',
                        value: '${result.roundedNetWpm}',
                        icon: Icons.speed_rounded,
                        large: true,
                      ),
                    ),
                    Expanded(
                      child: _ResultMetric(
                        label: 'Accuracy',
                        value: '${result.roundedAccuracy}%',
                        icon: Icons.check_circle_outline,
                        large: true,
                      ),
                    ),
                  ],
                ),
                const Gap(16),
                Row(
                  children: [
                    Expanded(
                      child: _ResultMetric(
                        label: 'Raw WPM',
                        value: '${result.roundedRawWpm}',
                        icon: Icons.bolt_outlined,
                      ),
                    ),
                    Expanded(
                      child: _ResultMetric(
                        label: 'Errors',
                        value: '${result.incorrectChars}',
                        icon: Icons.error_outline,
                      ),
                    ),
                    Expanded(
                      child: _ResultMetric(
                        label: 'Passages',
                        value: '${result.passagesCompleted}',
                        icon: Icons.layers_outlined,
                      ),
                    ),
                  ],
                ),
                const Gap(28),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onDone,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textSecondary(context),
                          side: BorderSide(
                              color: AppColors.borderStrong(context)),
                          minimumSize: const Size.fromHeight(46),
                        ),
                        child: const Text('Back to hub'),
                      ),
                    ),
                    const Gap(12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onRetry,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryText(),
                          foregroundColor: AppColors.onPrimary(context),
                          minimumSize: const Size.fromHeight(46),
                        ),
                        child: const Text('Try again'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final bool large;

  const _ResultMetric({
    required this.label,
    required this.value,
    this.icon,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final icon = this.icon;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: AppColors.textMuted(context)),
              const Gap(4),
            ],
            Text(
              label,
              style:
                  TextStyle(fontSize: 12, color: AppColors.textMuted(context)),
            ),
          ],
        ),
        const Gap(4),
        Text(
          value,
          style: TextStyle(
            fontSize: large ? 36 : 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
