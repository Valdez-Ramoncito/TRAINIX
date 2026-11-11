import 'dart:async';

import 'package:flutter/material.dart';
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
  static const _green = Color(0xFF70BD8A);
  static const _red = Color(0xFFF87171);
  static const _muted = Color(0xFF9CA3AF);
  static const _card = Color(0xFF1A1A1A);
  static const _border = Color(0xFF333333);

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
      backgroundColor: const Color(0xFF0F0F0F),
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
                            color: _card,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _border),
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
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            color: Colors.white,
                          ),
                          cursorColor: _green,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: _card,
                            hintText: _started
                                ? 'Keep typing...'
                                : 'Start typing to begin the timer',
                            hintStyle: const TextStyle(color: _muted),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: _border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: _border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: _green),
                            ),
                          ),
                          onChanged: _onTextChanged,
                        ),
                        const Gap(14),
                        Text(
                          widget.noBackspace
                              ? 'No-backspace mode is on. Escape to exit.'
                              : 'Timer starts on first key. Escape to exit.',
                          style: const TextStyle(
                            fontSize: 12,
                            color: _muted,
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
                    style: const TextStyle(fontSize: 12, color: _muted),
                  ),
                  const Spacer(),
                  Text(
                    '$_passagesCompleted completed · $_totalKeystrokes keys',
                    style: const TextStyle(fontSize: 12, color: _muted),
                  ),
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
          icon: const Icon(Icons.close, size: 18, color: Colors.white70),
          label: const Text('Exit', style: TextStyle(color: Colors.white70)),
        ),
        const Gap(16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF333333)),
          ),
          child: Text(
            '$_packLabel · ${durationSeconds}s'
            '${noBackspace ? ' · No BS' : ''}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
          ),
        ),
        const Spacer(),
        _StatChip(
          label: 'Time',
          value: '$mm:$ss',
          emphasize: urgent,
        ),
        const Gap(12),
        _StatChip(label: 'WPM', value: wpm.toStringAsFixed(0)),
        const Gap(12),
        _StatChip(label: 'Accuracy', value: '${accuracy.round()}%'),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasize;

  const _StatChip({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: emphasize ? const Color(0xFFF87171) : const Color(0xFF333333),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
          ),
          const Gap(2),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: emphasize ? const Color(0xFFF87171) : Colors.white,
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
    final maxLen =
        typed.length > target.length ? typed.length : target.length;

    for (var i = 0; i < maxLen; i++) {
      if (i < typed.length && i < target.length) {
        final ok = typed[i] == target[i];
        spans.add(
          TextSpan(
            text: target[i],
            style: TextStyle(
              color: ok ? const Color(0xFF70BD8A) : const Color(0xFFF87171),
              backgroundColor:
                  ok ? null : const Color(0xFFF87171).withValues(alpha: 0.18),
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      } else if (i < typed.length && i >= target.length) {
        spans.add(
          TextSpan(
            text: typed[i],
            style: TextStyle(
              color: const Color(0xFFF87171),
              backgroundColor:
                  const Color(0xFFF87171).withValues(alpha: 0.18),
            ),
          ),
        );
      } else if (i == typed.length && i < target.length) {
        spans.add(
          TextSpan(
            text: target[i],
            style: const TextStyle(
              color: Colors.white,
              decoration: TextDecoration.underline,
              decorationColor: Color(0xFF70BD8A),
            ),
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: target[i],
            style: const TextStyle(color: Color(0xFF6B7280)),
          ),
        );
      }
    }

    if (target.isEmpty) {
      spans.add(
        const TextSpan(
          text: 'No passage loaded.',
          style: TextStyle(color: Color(0xFF9CA3AF)),
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
      backgroundColor: const Color(0xFF0F0F0F),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF333333)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
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
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF9CA3AF),
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
                      color: const Color(0xFF70BD8A).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF70BD8A).withValues(alpha: 0.5),
                      ),
                    ),
                    child: const Text(
                      'Personal best for this mode',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF70BD8A),
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
                        large: true,
                      ),
                    ),
                    Expanded(
                      child: _ResultMetric(
                        label: 'Accuracy',
                        value: '${result.roundedAccuracy}%',
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
                      ),
                    ),
                    Expanded(
                      child: _ResultMetric(
                        label: 'Errors',
                        value: '${result.incorrectChars}',
                      ),
                    ),
                    Expanded(
                      child: _ResultMetric(
                        label: 'Passages',
                        value: '${result.passagesCompleted}',
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
                          foregroundColor: Colors.white70,
                          side: const BorderSide(color: Color(0xFF444444)),
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
                          backgroundColor: const Color(0xFF70BD8A),
                          foregroundColor: Colors.white,
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
  final bool large;

  const _ResultMetric({
    required this.label,
    required this.value,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
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
