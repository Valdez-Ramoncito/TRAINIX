import 'dart:async';
import 'package:flutter/material.dart';
import 'package:trainixprogram/components/app_colors.dart';
import 'package:gap/gap.dart';
import 'package:trainixprogram/models/simulation_coach.dart';
import 'package:trainixprogram/screens/settings_screen.dart';

class SessionGuidanceBanner extends StatefulWidget {
  final String objective;
  final String? tip;
  final DateTime? startedAt;
  final int ahtLimitSeconds;
  final bool customerConfirmed;
  final bool awaitingClosing;
  final bool hasTraineeSpoken;
  final bool hasCustomerSpoken;
  final String problem;
  final String sector;
  final int traineeTurnCount;
  final bool toolWorkDone;
  final String lastCustomerMessage;
  final bool isEscalating;
  final String lastTraineeMessage;
  final bool isChatChannel;

  const SessionGuidanceBanner({
    super.key,
    required this.objective,
    this.tip,
    this.startedAt,
    this.ahtLimitSeconds = SimulationCoach.ahtLimitSeconds,
    this.customerConfirmed = false,
    this.awaitingClosing = false,
    this.hasTraineeSpoken = false,
    this.hasCustomerSpoken = false,
    this.problem = '',
    this.sector = '',
    this.traineeTurnCount = 0,
    this.toolWorkDone = false,
    this.lastCustomerMessage = '',
    this.isEscalating = false,
    this.lastTraineeMessage = '',
    this.isChatChannel = true,
  });

  @override
  State<SessionGuidanceBanner> createState() => _SessionGuidanceBannerState();
}

class _SessionGuidanceBannerState extends State<SessionGuidanceBanner> {
  Timer? _ticker;
  int _elapsedSeconds = 0;
  String? _lastTip;
  bool _tipPulse = false;
  final Set<int> _firedMilestones = {};
  String? _milestoneMessage;

  static const List<int> _milestones = [120, 300, 420, 600];

  @override
  void initState() {
    super.initState();
    _syncElapsed();
    _lastTip = _tip;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _syncElapsed();
    });
  }

  @override
  void didUpdateWidget(covariant SessionGuidanceBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.startedAt != widget.startedAt) {
      _firedMilestones.clear();
      _milestoneMessage = null;
      _syncElapsed();
    }
    final nextTip = _tip;
    if (nextTip != null && nextTip.isNotEmpty && nextTip != _lastTip) {
      _lastTip = nextTip;
      setState(() => _tipPulse = true);
      Future.delayed(const Duration(milliseconds: 1600), () {
        if (mounted) setState(() => _tipPulse = false);
      });
    }
  }

  void _syncElapsed() {
    final started = widget.startedAt;
    final next =
        started == null ? 0 : DateTime.now().difference(started).inSeconds;
    if (next != _elapsedSeconds) {
      setState(() {
        _elapsedSeconds = next;
        if (AppSettings.ahtAlertsEnabled) {
          for (final m in _milestones) {
            if (next >= m && !_firedMilestones.contains(m)) {
              _firedMilestones.add(m);
              _milestoneMessage = _milestoneText(m);
            }
          }
        }
      });
    }
  }

  String _milestoneText(int seconds) {
    final mins = seconds ~/ 60;
    if (seconds >= widget.ahtLimitSeconds) {
      return 'AHT limit reached ($mins min). Wrap up when the customer is ready.';
    }
    if (mins == 2) {
      return '2 minutes on this customer. Stay focused and move the case forward.';
    }
    if (mins == 5) {
      return '5 minutes on this customer. Summarize progress and drive toward resolution.';
    }
    if (mins == 7) {
      return '7 minutes on this customer. Confirm a clear next step or outcome with the customer.';
    }
    return '$mins minutes on this customer.';
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String? get _tip {
    if (!AppSettings.coachTipsEnabled) return null;
    if (widget.tip != null && widget.tip!.isNotEmpty) return widget.tip;
    return SimulationCoach.tipForState(
      customerConfirmed: widget.customerConfirmed,
      awaitingClosing: widget.awaitingClosing,
      hasTraineeSpoken: widget.hasTraineeSpoken,
      hasCustomerSpoken: widget.hasCustomerSpoken,
      problem: widget.problem,
      sector: widget.sector,
      elapsedSeconds: _elapsedSeconds,
      traineeTurnCount: widget.traineeTurnCount,
      toolWorkDone: widget.toolWorkDone,
      lastCustomerMessage: widget.lastCustomerMessage,
      isEscalating: widget.isEscalating,
      lastTraineeMessage: widget.lastTraineeMessage,
      isChatChannel: widget.isChatChannel,
    );
  }

  String? get _tipSourceLabel {
    if (!AppSettings.coachTipsEnabled) return null;
    if (widget.tip != null && widget.tip!.isNotEmpty) return 'Scenario tip';
    final tip = _tip;
    if (tip != null && tip.isNotEmpty) return 'AI coach tip';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final ahtWarning =
        widget.startedAt != null && _elapsedSeconds > widget.ahtLimitSeconds;
    final tip = _tip;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.panel(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _tipPulse
              ? AppColors.secondaryText()
              : ahtWarning
                  ? AppColors.warningText()
                  : AppColors.borderIdle(context),
          width: _tipPulse ? 1.4 : 0.5,
        ),
        boxShadow: _tipPulse
            ? [
                BoxShadow(
                  color: AppColors.secondaryText().withValues(alpha: 0.45),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.flag_outlined,
                size: 16,
                color: AppColors.primaryText(),
              ),
              const Gap(8),
              Text(
                'Objective',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryText(),
                ),
              ),
              if (widget.startedAt != null) ...[
                const Spacer(),
                Text(
                  _format(_elapsedSeconds),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: ahtWarning
                        ? AppColors.warningText()
                        : AppColors.textMuted(context),
                  ),
                ),
              ],
            ],
          ),
          const Gap(6),
          Text(
            widget.objective,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary(context),
              height: 1.35,
            ),
          ),
          if (tip != null && tip.isNotEmpty) ...[
            const Gap(8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 14,
                  color: _tipPulse
                      ? AppColors.secondaryText()
                      : AppColors.secondaryText(),
                ),
                const Gap(6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_tipSourceLabel != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            _tipSourceLabel!,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMuted(context),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      Text(
                        tip,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.secondaryText(),
                          height: 1.35,
                          fontWeight:
                              _tipPulse ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
          if (_milestoneMessage != null) ...[
            const Gap(8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.elevated(context),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.warningText()),
              ),
              child: Text(
                _milestoneMessage!,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.warningText(),
                  height: 1.3,
                ),
              ),
            ),
          ],
          if (ahtWarning) ...[
            const Gap(6),
            Text(
              'Over target handle time. Wrap up and close when the customer is ready.',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.warningText(),
                height: 1.3,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _format(int total) {
    final m = (total ~/ 60).toString().padLeft(2, '0');
    final s = (total % 60).toString().padLeft(2, '0');
    final limM = (widget.ahtLimitSeconds ~/ 60).toString().padLeft(2, '0');
    final limS = (widget.ahtLimitSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s / $limM:$limS';
  }
}
