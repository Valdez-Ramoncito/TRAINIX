import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:trainixprogram/models/training/script_personalization.dart';
import 'package:trainixprogram/models/training/training_categories.dart';
import 'package:trainixprogram/models/training/voice_line_player.dart';
import 'package:trainixprogram/models/training/voice_scoring/voice_delivery_scorer.dart';
import 'package:trainixprogram/models/training/voice_scoring/voice_script_scorer.dart';
import 'package:trainixprogram/models/training/voice_scoring/voice_score_result.dart';
import 'package:trainixprogram/services/speech_to_text_service.dart';

class AssessmentVoiceView extends StatefulWidget {
  final Assessment item;
  final bool lockedIn;
  final bool useDeliveryScoring;
  final void Function(bool passed) onCompleted;

  const AssessmentVoiceView({
    super.key,
    required this.item,
    required this.lockedIn,
    required this.onCompleted,
    this.useDeliveryScoring = false,
  });

  @override
  State<AssessmentVoiceView> createState() => _AssessmentVoiceViewState();
}

class _AssessmentVoiceViewState extends State<AssessmentVoiceView> {
  final SpeechToTextService _stt = SpeechToTextService();
  bool _ready = false;
  bool _recording = false;
  bool _processing = false;
  bool _playingExample = false;
  bool _playingTake = false;
  VoiceScoreResult? _result;
  String _status = '';
  String? _lastAudioPath;

  @override
  void initState() {
    super.initState();
    _initMic();
  }

  @override
  void dispose() {
    VoiceLinePlayer.instance.stop();
    if (_lastAudioPath != null) {
      _stt.deleteRetainedFile(_lastAudioPath);
    }
    _stt.dispose();
    super.dispose();
  }

  bool _didAutoPlayExample = false;

  Future<void> _initMic() async {
    final ok = await _stt.initialize();
    if (!mounted) return;
    setState(() {
      _ready = ok;
      if (!ok) {
        _status = 'Microphone is not available.';
      }
    });
    if (ok && !_didAutoPlayExample && !widget.lockedIn) {
      _didAutoPlayExample = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _playExample();
      });
    }
  }

  Future<void> _playExample() async {
    if (_recording || _processing || _playingExample) return;
    final target = ScriptPersonalization.resolve(
      widget.item.voiceTargetScript ?? '',
    );
    if (target.isEmpty) return;
    setState(() {
      _playingExample = true;
      _status = 'Playing example...';
    });
    await VoiceLinePlayer.instance.playText(target, emotion: 'professional');
    if (!mounted) return;
    setState(() {
      _playingExample = false;
      if (_result == null) _status = '';
    });
  }

  Future<void> _playLastTake() async {
    final path = _lastAudioPath;
    if (path == null || _recording || _processing || _playingTake) return;
    setState(() {
      _playingTake = true;
      _status = 'Playing your recording...';
    });
    await VoiceLinePlayer.instance.playFile(path);
    if (!mounted) return;
    setState(() {
      _playingTake = false;
      if (_result != null) {
        _status = _result!.passed ? 'Passed' : 'Not passed yet';
      } else {
        _status = '';
      }
    });
  }

  Future<void> _start() async {
    if (!_ready || _recording || _processing || widget.lockedIn) return;
    await VoiceLinePlayer.instance.stop();
    setState(() {
      _status = 'Recording...';
      _result = null;
    });
    await _stt.startListening(onResult: (_) {});
    if (!mounted) return;
    setState(() {
      _recording = true;
    });
  }

  Future<void> _stopAndScore() async {
    if (!_recording || _processing) return;
    setState(() {
      _recording = false;
      _processing = true;
      _status = 'Checking your reply...';
    });

    final result = await _stt.stopListening();
    final transcript = result.$1;
    final audioPath = result.$2;
    if (!mounted) return;

    if (_lastAudioPath != null && _lastAudioPath != audioPath) {
      await _stt.deleteRetainedFile(_lastAudioPath);
    }
    _lastAudioPath = audioPath;

    final cleaned = transcript.trim();
    if (cleaned.isEmpty) {
      if (!mounted) return;
      setState(() {
        _processing = false;
        _result = const VoiceScoreResult(
          transcript: '',
          contentScore: 0,
          deliveryScore: 0,
          totalScore: 0,
          passed: false,
          criticalFail: true,
          criticalFailReason:
              'Nothing to score. No speech was detected. Try again and speak the line clearly.',
          contentNotes: [],
          deliveryNotes: [],
          deliveryEvaluated: false,
        );
        _status = 'No speech detected';
      });
      widget.onCompleted(false);
      return;
    }

    final target = ScriptPersonalization.resolve(
      widget.item.voiceTargetScript ?? '',
    );
    late final scored;

    if (widget.useDeliveryScoring) {
      setState(() {
        _status = 'Checking content and delivery...';
      });
      scored = await VoiceDeliveryScorer.score(
        transcript: transcript,
        targetScript: target,
        audioPath: audioPath,
      );
    } else {
      setState(() {
        _status = 'Checking how closely the line matches...';
      });
      scored = VoiceScriptScorer.scoreScriptOnly(
        transcript: transcript,
        targetScript: target,
      );
    }

    if (!mounted) return;

    setState(() {
      _processing = false;
      _result = scored;
      _status = scored.passed ? 'Passed' : 'Not passed yet';
    });

    widget.onCompleted(scored.passed);
  }

  @override
  Widget build(BuildContext context) {
    final target = ScriptPersonalization.resolve(
      widget.item.voiceTargetScript ?? '',
    );

    final audioBtnStyle = OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFF70BD8A),
      side: const BorderSide(color: Color(0xFF2E4A38)),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Say this out loud clearly',
          style: TextStyle(fontSize: 13, color: Colors.white54),
        ),
        const Gap(10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              style: audioBtnStyle,
              onPressed: (_recording || _processing || _playingExample)
                  ? null
                  : _playExample,
              icon: Icon(
                _playingExample ? Icons.hourglass_top : Icons.volume_up,
                size: 18,
              ),
              label: Text(_playingExample ? 'Playing...' : 'Hear example'),
            ),
            if (_lastAudioPath != null)
              OutlinedButton.icon(
                style: audioBtnStyle,
                onPressed: (_recording || _processing || _playingTake)
                    ? null
                    : _playLastTake,
                icon: Icon(
                  _playingTake ? Icons.hourglass_top : Icons.play_arrow,
                  size: 18,
                ),
                label: Text(_playingTake ? 'Playing...' : 'Play my recording'),
              ),
          ],
        ),
        const Gap(12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF333333)),
          ),
          child: Text(
            target,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
        ),
        const Gap(12),
        Text(
          widget.useDeliveryScoring
              ? 'Scored on content match and how clearly you deliver the line. Pass mark is about 75% overall.'
              : 'Scored on how closely your spoken line matches the target. Small wording differences are allowed.',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white38,
            height: 1.35,
          ),
        ),
        const Gap(16),
        if (!widget.lockedIn) ...[
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _recording ? Colors.redAccent : Colors.green,
                foregroundColor: Colors.white,
              ),
              onPressed: _processing
                  ? null
                  : (_recording ? _stopAndScore : _start),
              child: Text(
                _processing
                    ? 'Processing...'
                    : (_recording ? 'Stop and Check' : 'Start Recording'),
              ),
            ),
          ),
        ],
        if (_status.isNotEmpty) ...[
          const Gap(10),
          Text(
            _status,
            style: TextStyle(
              fontSize: 13,
              color: _result == null
                  ? Colors.white54
                  : (_result!.passed ? Colors.green : Colors.redAccent),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        if (_result != null) ...[
          const Gap(12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _result!.passed
                  ? const Color(0xFF1A3A1A)
                  : const Color(0xFF3A1A1A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _result!.passed
                    ? Colors.green.withOpacity(0.5)
                    : Colors.redAccent.withOpacity(0.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _result!.passed
                      ? 'Passed'
                      : (_result!.criticalFail
                            ? 'Nothing to score'
                            : 'Incorrect / Not passed'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _result!.passed ? Colors.green : Colors.redAccent,
                  ),
                ),
                if (_result!.criticalFail &&
                    _result!.criticalFailReason.isNotEmpty) ...[
                  const Gap(8),
                  Text(
                    _result!.criticalFailReason,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                      height: 1.35,
                    ),
                  ),
                ],
                const Gap(8),
                Text(
                  'Total: ${_result!.totalScore}/100',
                  style: const TextStyle(fontSize: 13, color: Colors.white70),
                ),
                Text(
                  'Content Accuracy: ${_result!.contentScore}/50',
                  style: const TextStyle(fontSize: 13, color: Colors.white70),
                ),
                if (_result!.deliveryEvaluated)
                  Text(
                    'Delivery Quality: ${_result!.deliveryScore}/50',
                    style: const TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                if (_result!.transcript.isNotEmpty) ...[
                  const Gap(8),
                  const Text(
                    'Your transcript',
                    style: TextStyle(fontSize: 12, color: Colors.white54),
                  ),
                  Text(
                    _result!.transcript,
                    style: const TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
