import 'package:flutter/material.dart';
import 'package:trainixprogram/components/app_colors.dart';
import 'package:gap/gap.dart';
import 'package:trainixprogram/models/scoring_transparency.dart';
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
  final void Function(VoiceScoreResult result) onCompleted;

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
      const emptyResult = VoiceScoreResult(
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
      setState(() {
        _processing = false;
        _result = emptyResult;
        _status = 'No speech detected';
      });
      widget.onCompleted(emptyResult);
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

    widget.onCompleted(scored);
  }

  @override
  Widget build(BuildContext context) {
    final target = ScriptPersonalization.resolve(
      widget.item.voiceTargetScript ?? '',
    );

    final audioBtnStyle = OutlinedButton.styleFrom(
      foregroundColor: AppColors.primaryText(),
      side: BorderSide(color: AppColors.nextTint(context)),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Say this out loud clearly',
          style: TextStyle(fontSize: 13, color: AppColors.textMuted(context)),
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
            color: AppColors.elevated(context),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border(context)),
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
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textMuted(context),
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
                backgroundColor: _recording
                    ? AppColors.errorText()
                    : AppColors.primary(context),
                foregroundColor: AppColors.onPrimary(context),
              ),
              onPressed:
                  _processing ? null : (_recording ? _stopAndScore : _start),
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
                  ? AppColors.textMuted(context)
                  : (_result!.passed
                      ? AppColors.primary(context)
                      : AppColors.errorText()),
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
                  ? AppColors.nextTint(context)
                  : AppColors.elevated(context),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _result!.passed
                    ? AppColors.primary(context).withValues(alpha: 0.5)
                    : AppColors.errorText().withOpacity(0.5),
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
                    color: _result!.passed
                        ? AppColors.primary(context)
                        : AppColors.errorText(),
                  ),
                ),
                if (_result!.criticalFail &&
                    _result!.criticalFailReason.isNotEmpty) ...[
                  const Gap(8),
                  Text(
                    _result!.criticalFailReason,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary(context),
                      height: 1.35,
                    ),
                  ),
                ],
                const Gap(8),
                Text(
                  'Total: ${_result!.totalScore}/100',
                  style: TextStyle(
                      fontSize: 13, color: AppColors.textSecondary(context)),
                ),
                Text(
                  'Content Accuracy: ${_result!.contentScore}/50',
                  style: TextStyle(
                      fontSize: 13, color: AppColors.textSecondary(context)),
                ),
                if (_result!.deliveryEvaluated)
                  Text(
                    'Delivery Quality: ${_result!.deliveryScore}/50',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textSecondary(context)),
                  ),
                if (_result!.deliveryEvaluated) ...[
                  const Gap(8),
                  Text(
                    'Clarity ${_result!.clarityScore}/15  |  Pace ${_result!.paceScore}/10  |  Tone ${_result!.toneScore}/15  |  Confidence ${_result!.confidenceScore}/10',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textSecondary(context)),
                  ),
                ],
                const Gap(8),
                Text(
                  _result!.deliveryEvaluated
                      ? '${ScoringTransparency.voiceInstrumentLine} ${ScoringTransparency.deliveryRubricLine}'
                      : '${ScoringTransparency.voiceInstrumentLine} ${ScoringTransparency.scriptContentLine}',
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.35,
                    color: AppColors.textMuted(context),
                  ),
                ),
                if (_result!.contentNotes.isNotEmpty) ...[
                  const Gap(8),
                  Text(
                    'Content notes',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textMuted(context)),
                  ),
                  for (final note in _result!.contentNotes)
                    Text(
                      note,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                ],
                if (_result!.deliveryNotes.isNotEmpty) ...[
                  const Gap(8),
                  Text(
                    'Delivery notes',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textMuted(context)),
                  ),
                  for (final note in _result!.deliveryNotes)
                    Text(
                      note,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                ],
                if (_result!.transcript.isNotEmpty) ...[
                  const Gap(8),
                  Text(
                    'Your transcript',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textMuted(context)),
                  ),
                  Text(
                    _result!.transcript,
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textSecondary(context)),
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
