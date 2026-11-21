import 'package:flutter/material.dart';
import 'package:trainixprogram/components/app_colors.dart';
import 'package:gap/gap.dart';
import 'package:trainixprogram/models/simulation_phase.dart';

class LeftCall extends StatefulWidget {
  final String sector;
  final SimulationPhase phase;
  final VoidCallback? onAccept;
  final int remainingBreakSeconds;
  final String customerType;

  const LeftCall({
    super.key,
    required this.sector,
    this.phase = SimulationPhase.incoming,
    this.onAccept,
    this.remainingBreakSeconds = 0,
    this.customerType = 'New Customer',
  });

  @override
  State<LeftCall> createState() => _LeftCallState();
}

class _LeftCallState extends State<LeftCall>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String titleText;
    IconData centerIcon;
    Color iconColor;
    Color outerRingColor;
    Color innerCircleColor;

    switch (widget.phase) {
      case SimulationPhase.active:
        titleText = 'Call in Progress';
        centerIcon = Icons.headset_mic_rounded;
        iconColor = AppColors.secondaryText();
        outerRingColor = AppColors.secondaryText().withValues(alpha: 0.35);
        innerCircleColor = AppColors.elevated(context);
        break;
      case SimulationPhase.onHold:
        titleText = 'Call on Hold';
        centerIcon = Icons.pause_circle_filled_rounded;
        iconColor = AppColors.warningText();
        outerRingColor = AppColors.warningText().withValues(alpha: 0.35);
        innerCircleColor = AppColors.elevated(context);
        break;
      case SimulationPhase.afterCallWork:
        titleText = 'After Call Work';
        centerIcon = Icons.assignment_outlined;
        iconColor = AppColors.secondaryText();
        outerRingColor = AppColors.secondaryText().withOpacity(0.35);
        innerCircleColor = AppColors.elevated(context);
        break;
      case SimulationPhase.postCallBreak:
        titleText = 'Grace Period (${widget.remainingBreakSeconds}s)';
        centerIcon = Icons.coffee_rounded;
        iconColor = AppColors.secondaryText();
        outerRingColor = AppColors.secondaryText().withValues(alpha: 0.35);
        innerCircleColor = AppColors.elevated(context);
        break;
      case SimulationPhase.wrappingUp:
        titleText = 'Session Wrapping Up';
        centerIcon = Icons.task_alt_rounded;
        iconColor = AppColors.successText();
        outerRingColor = AppColors.primaryText().withValues(alpha: 0.35);
        innerCircleColor = AppColors.elevated(context);
        break;
      case SimulationPhase.incoming:
        titleText = 'Incoming Call';
        centerIcon = Icons.phone_in_talk_rounded;
        iconColor = AppColors.onPrimary(context);
        outerRingColor = AppColors.primaryText().withValues(alpha: 0.5);
        innerCircleColor = AppColors.primaryText();
        break;
    }

    return Container(
      color: Theme.of(context).colorScheme.surface,
      width: double.infinity,
      height: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Double concentric circle call avatar with subtle pulse animation
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: widget.phase == SimulationPhase.incoming
                    ? _pulseAnimation.value
                    : 1.0,
                child: child,
              );
            },
            child: Container(
              width: 210,
              height: 210,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: outerRingColor, width: 1.5),
              ),
              child: Center(
                child: Container(
                  width: 165,
                  height: 165,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: innerCircleColor,
                    border: Border.all(
                      color: iconColor.withValues(alpha: 0.3),
                      width: 1.2,
                    ),
                    boxShadow: Theme.of(context).brightness == Brightness.dark
                        ? null
                        : [
                            BoxShadow(
                              color: innerCircleColor.withValues(alpha: 0.28),
                              blurRadius: 26,
                              offset: const Offset(0, 10),
                            ),
                          ],
                  ),
                  child: Icon(centerIcon, size: 56, color: iconColor),
                ),
              ),
            ),
          ),
          const Gap(28),

          // Title: "Incoming Call"
          Text(
            titleText,
            style: TextStyle(
              color: AppColors.textPrimary(context),
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          const Gap(12),

          // Subtitle pill: [New Customer] · Tech Support
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.elevated(context),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  widget.customerType,
                  style: TextStyle(
                    color: AppColors.textMuted(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Gap(8),
              Text(
                '·',
                style: TextStyle(
                  color: AppColors.textMuted(context),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Gap(8),
              Text(
                widget.sector,
                style: TextStyle(
                  color: AppColors.textMuted(context),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),

          // If incoming phase, show green Accept call button below
          if (widget.phase == SimulationPhase.incoming &&
              widget.onAccept != null) ...[
            const Gap(36),
            ElevatedButton.icon(
              onPressed: widget.onAccept,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryText(),
                foregroundColor: AppColors.onPrimary(context),
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 4,
              ),
              icon: const Icon(Icons.call_rounded, size: 22),
              label: const Text(
                'Accept Call',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
