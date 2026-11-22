import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:trainixprogram/components/app_colors.dart';
import 'package:trainixprogram/models/training/speaking/speaking_practice_store.dart';
import 'package:trainixprogram/models/training/speaking/speaking_prompt.dart';
import 'package:trainixprogram/models/training/speaking/speaking_result.dart';
import 'package:trainixprogram/screens/page/components/mini_training/speaking_practice/speaking_result_view.dart';
import 'package:trainixprogram/services/speaking_evaluation_api_service.dart';
import 'package:trainixprogram/services/speech_to_text_service.dart';

enum _SpeakPhase {
  ready,
  permissionDenied,
  recording,
  transcribing,
  scoring,
  result,
  failed,
}

class SpeakingTestScreen extends StatefulWidget {
  final SpeakingPrompt prompt;

  const SpeakingTestScreen({super.key, required this.prompt});

  @override
  State<SpeakingTestScreen> createState() => _SpeakingTestScreenState();
}

class _SpeakingTestScreenState extends State<SpeakingTestScreen> {
  final SpeechToTextService _stt = SpeechToTextService();

  _SpeakPhase _phase = _SpeakPhase.ready;
  int _elapsedSeconds = 0;
  Timer? _timer;
  String? _audioPath;
  String? _error;
  SpeakingResult? _result;
  bool _aiAvailable = true;
  String? _aiNote;
  int _attempt = 0;
  final SpeakingEvaluationApiService _scorer = SpeakingEvaluationApiService();

  int get _maxSeconds => widget.prompt.targetSeconds + 15;

  @override
  void initState() {
    super.initState();
    _prepareMic();
  }

  Future<void> _prepareMic() async {
    final ok = await _stt.initialize();
    if (!mounted) return;
    if (!ok) {
      setState(() => _phase = _SpeakPhase.permissionDenied);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stt.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    if (_phase == _SpeakPhase.recording || _phase == _SpeakPhase.transcribing) {
      return;
    }
    final ok = await _stt.initialize();
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _phase = _SpeakPhase.permissionDenied;
        _error = 'Microphone permission is required for Speaking Practice.';
      });
      return;
    }

    setState(() {
      _phase = _SpeakPhase.recording;
      _elapsedSeconds = 0;
      _audioPath = null;
      _error = null;
      _result = null;
      _attempt += 1;
    });

    await _stt.startListening(onResult: (_) {});
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _phase != _SpeakPhase.recording) return;
      setState(() {
        _elapsedSeconds += 1;
        if (_elapsedSeconds >= _maxSeconds) {
          _stop();
        }
      });
    });
  }

  Future<void> _stop() async {
    if (_phase != _SpeakPhase.recording) return;
    _timer?.cancel();
    setState(() => _phase = _SpeakPhase.transcribing);

    final (transcript, path) = await _stt.stopListening();
    if (!mounted) return;

    final cleaned = transcript.trim();
    final wordCount = cleaned.isEmpty
        ? 0
        : cleaned.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    // Reject empty, near-empty, or too-short takes so silence/noise is not scored.
    if (cleaned.isEmpty || wordCount < 3 || _elapsedSeconds < 2) {
      setState(() {
        _phase = _SpeakPhase.failed;
        _audioPath = path;
        _error = cleaned.isEmpty || wordCount < 3
            ? 'No usable speech was detected. Keep the mic close and try again. Your attempt was not scored.'
            : 'Recording was too short to score. Speak for at least a couple of seconds.';
      });
      return;
    }

    setState(() {
      _audioPath = path;
      _phase = _SpeakPhase.scoring;
    });

    final evaluation = await _scorer.scoreSpeaking(
      prompt: widget.prompt,
      transcript: cleaned,
      durationSeconds: _elapsedSeconds.clamp(1, _maxSeconds),
      audioPath: path,
    );
    if (!mounted) return;

    SpeakingPracticeStore.record(evaluation.result);
    setState(() {
      _result = evaluation.result;
      _aiAvailable = evaluation.aiAvailable;
      _aiNote = evaluation.aiNote;
      _phase = _SpeakPhase.result;
    });
  }

  Future<void> _retry() async {
    if (_audioPath != null) {
      await _stt.deleteRetainedFile(_audioPath);
      _audioPath = null;
    }
    setState(() {
      _phase = _SpeakPhase.ready;
      _error = null;
      _result = null;
      _elapsedSeconds = 0;
    });
  }

  Future<void> _done() async {
    if (_audioPath != null) {
      await _stt.deleteRetainedFile(_audioPath);
      _audioPath = null;
    }
    if (mounted) Navigator.pop(context, true);
  }

  String _fmt(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    if (_phase == _SpeakPhase.result && _result != null) {
      return SpeakingResultView(
        result: _result!,
        prompt: widget.prompt,
        aiAvailable: _aiAvailable,
        aiNote: _aiNote,
        onRetake: () async {
          await _retry();
        },
        onNewPrompt: () async {
          if (_audioPath != null) {
            await _stt.deleteRetainedFile(_audioPath);
            _audioPath = null;
          }
          if (mounted) Navigator.pop(context, true);
        },
        onDone: () async {
          await _done();
        },
      );
    }

    final prompt = widget.prompt;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TopBar(
                packLabel: '${prompt.pack.label} · ${prompt.difficulty.label}',
                elapsed: _fmt(_elapsedSeconds),
                maxLabel: _fmt(_maxSeconds),
                phase: _phase,
                onExit: () async {
                  if (_phase == _SpeakPhase.recording) {
                    _stt.cancel();
                    _timer?.cancel();
                  }
                  if (_audioPath != null) {
                    await _stt.deleteRetainedFile(_audioPath);
                  }
                  if (mounted) Navigator.pop(context);
                },
              ),
              const Gap(18),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: _buildBody(prompt),
                  ),
                ),
              ),
              const Gap(12),
              _BottomActions(
                phase: _phase,
                onStart: _start,
                onStop: _stop,
                onRetry: _retry,
                onDone: _done,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(SpeakingPrompt prompt) {
    switch (_phase) {
      case _SpeakPhase.permissionDenied:
        return _MessageCard(
          icon: Icons.mic_off_rounded,
          title: 'Microphone access needed',
          body:
              'Allow microphone permission in system settings, then return and press Start recording.',
          tone: AppColors.warningText(),
        );
      case _SpeakPhase.ready:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PromptCard(prompt: prompt),
            const Gap(16),
            Text(
              'Press Start when you are ready. Recording auto-stops at target time plus 15 seconds.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textMuted(context),
                fontSize: 13,
              ),
            ),
            if (_attempt > 0) ...[
              const Gap(8),
              Text(
                'Attempt $_attempt',
                style: TextStyle(
                  color: AppColors.textMuted(context),
                  fontSize: 12,
                ),
              ),
            ],
          ],
        );
      case _SpeakPhase.recording:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PromptCard(prompt: prompt, recording: true),
            const Gap(20),
            _MicPulse(active: true),
            const Gap(12),
            Text(
              'Recording… speak clearly',
              style: TextStyle(
                color: AppColors.errorText(),
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap(6),
            Text(
              '${_fmt(_elapsedSeconds)} / ${_fmt(_maxSeconds)}',
              style: TextStyle(
                color: AppColors.textSecondary(context),
                fontSize: 13,
              ),
            ),
          ],
        );
      case _SpeakPhase.transcribing:
      case _SpeakPhase.scoring:
        final scoring = _phase == _SpeakPhase.scoring;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const Gap(16),
            Text(
              scoring
                  ? 'Scoring your take…'
                  : 'Transcribing your recording…',
              style: TextStyle(
                color: AppColors.textSecondary(context),
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap(6),
            Text(
              scoring
                  ? 'AI dimensions load when the model is reachable. Measured metrics always save.'
                  : 'This uses AssemblyAI and may take a few seconds.',
              style: TextStyle(
                color: AppColors.textMuted(context),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        );
      case _SpeakPhase.failed:
        return _MessageCard(
          icon: Icons.hearing_disabled_rounded,
          title: 'Could not score this take',
          body: _error ?? 'Empty transcript.',
          tone: AppColors.warningText(),
        );
      case _SpeakPhase.result:
        return const SizedBox.shrink();
    }
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.packLabel,
    required this.elapsed,
    required this.maxLabel,
    required this.phase,
    required this.onExit,
  });

  final String packLabel;
  final String elapsed;
  final String maxLabel;
  final _SpeakPhase phase;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TextButton.icon(
          onPressed: onExit,
          icon: const Icon(Icons.close_rounded, size: 18),
          label: const Text('Exit'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textSecondary(context),
          ),
        ),
        const Gap(8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.chipBg(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderIdle(context)),
          ),
          child: Text(
            packLabel,
            style: TextStyle(
              color: AppColors.textSecondary(context),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Spacer(),
        _StatChip(
          label: 'Time',
          value: phase == _SpeakPhase.recording ? elapsed : maxLabel,
        ),
        const Gap(8),
        _StatChip(
          label: 'Phase',
          value: switch (phase) {
            _SpeakPhase.ready => 'Ready',
            _SpeakPhase.permissionDenied => 'Mic',
            _SpeakPhase.recording => 'Live',
            _SpeakPhase.transcribing => 'STT',
            _SpeakPhase.scoring => 'Score',
            _SpeakPhase.result => 'Done',
            _SpeakPhase.failed => 'Retry',
          },
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderIdle(context)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.textMuted(context),
              fontSize: 10,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimary(context),
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _PromptCard extends StatelessWidget {
  const _PromptCard({required this.prompt, this.recording = false});

  final SpeakingPrompt prompt;
  final bool recording;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: recording
              ? AppColors.errorText().withValues(alpha: 0.45)
              : AppColors.borderIdle(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.record_voice_over_outlined,
                size: 18,
                color: AppColors.secondaryText(),
              ),
              const Gap(8),
              Expanded(
                child: Text(
                  prompt.label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              Text(
                '~${prompt.targetSeconds}s',
                style: TextStyle(
                  color: AppColors.textMuted(context),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const Gap(12),
          Text(
            prompt.text,
            style: TextStyle(
              color: AppColors.textPrimary(context),
              fontSize: 16,
              height: 1.45,
            ),
          ),
          if (prompt.focus.isNotEmpty) ...[
            const Gap(12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: prompt.focus
                  .map(
                    (f) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.chipBg(context),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        f,
                        style: TextStyle(
                          color: AppColors.textSecondary(context),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _MicPulse extends StatelessWidget {
  const _MicPulse({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active
            ? AppColors.errorText().withValues(alpha: 0.12)
            : AppColors.chipBg(context),
        border: Border.all(
          color: active
              ? AppColors.errorText().withValues(alpha: 0.5)
              : AppColors.borderIdle(context),
          width: 2,
        ),
      ),
      child: Icon(
        Icons.mic_rounded,
        size: 32,
        color: active ? AppColors.errorText() : AppColors.textMuted(context),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.tone,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderIdle(context)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 36, color: tone),
          const Gap(12),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const Gap(8),
          Text(
            body,
            style: TextStyle(
              color: AppColors.textSecondary(context),
              fontSize: 13,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.phase,
    required this.onStart,
    required this.onStop,
    required this.onRetry,
    required this.onDone,
  });

  final _SpeakPhase phase;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onRetry;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final primary = switch (phase) {
      _SpeakPhase.ready || _SpeakPhase.permissionDenied => (
          'Start recording',
          onStart,
          Icons.mic_rounded,
        ),
      _SpeakPhase.recording => (
          'Stop',
          onStop,
          Icons.stop_rounded,
        ),
      _SpeakPhase.transcribing => (
          'Transcribing…',
          null,
          Icons.hourglass_top_rounded,
        ),
      _SpeakPhase.scoring => (
          'Scoring…',
          null,
          Icons.hourglass_top_rounded,
        ),
      _SpeakPhase.failed => (
          'Try again',
          onRetry,
          Icons.refresh_rounded,
        ),
      _SpeakPhase.result => (
          'Done',
          onDone,
          Icons.check_rounded,
        ),
    };

    return Row(
      children: [
        if (phase == _SpeakPhase.result) ...[
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retake'),
          ),
          const Gap(10),
        ],
        Expanded(
          child: SizedBox(
            height: 46,
            child: ElevatedButton.icon(
              onPressed: primary.$2,
              icon: Icon(primary.$3, size: 18),
              label: Text(primary.$1),
              style: ElevatedButton.styleFrom(
                backgroundColor: phase == _SpeakPhase.recording
                    ? AppColors.errorText()
                    : AppColors.primaryText(),
                foregroundColor: AppColors.onPrimary(context),
                disabledBackgroundColor: AppColors.border(context),
                disabledForegroundColor: AppColors.textMuted(context),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
