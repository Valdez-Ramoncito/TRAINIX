import 'package:flutter/material.dart';
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
        iconColor = const Color(0xFF60A5FA);
        outerRingColor = const Color(0xFF2563EB).withOpacity(0.35);
        innerCircleColor = const Color(0xFF1E293B);
        break;
      case SimulationPhase.onHold:
        titleText = 'Call on Hold';
        centerIcon = Icons.pause_circle_filled_rounded;
        iconColor = const Color(0xFFF59E0B);
        outerRingColor = const Color(0xFFD97706).withOpacity(0.35);
        innerCircleColor = const Color(0xFF27272A);
        break;
      case SimulationPhase.afterCallWork:
        titleText = 'After Call Work';
        centerIcon = Icons.assignment_outlined;
        iconColor = const Color(0xFF38BDF8);
        outerRingColor = const Color(0xFF0284C7).withOpacity(0.35);
        innerCircleColor = const Color(0xFF1E293B);
        break;
      case SimulationPhase.postCallBreak:
        titleText = 'Grace Period (${widget.remainingBreakSeconds}s)';
        centerIcon = Icons.coffee_rounded;
        iconColor = const Color(0xFFA855F7);
        outerRingColor = const Color(0xFF9333EA).withOpacity(0.35);
        innerCircleColor = const Color(0xFF1E293B);
        break;
      case SimulationPhase.wrappingUp:
        titleText = 'Session Wrapping Up';
        centerIcon = Icons.task_alt_rounded;
        iconColor = const Color(0xFF34D399);
        outerRingColor = const Color(0xFF059669).withOpacity(0.35);
        innerCircleColor = const Color(0xFF1E293B);
        break;
      case SimulationPhase.incoming:
        titleText = 'Incoming Call';
        centerIcon = Icons.phone_in_talk_rounded;
        iconColor = const Color.fromARGB(255, 169, 226, 189);
        outerRingColor = const Color(0xFF16A34A).withOpacity(0.5);
        innerCircleColor = Color.fromARGB(110, 22, 163, 74);
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
                      color: iconColor.withOpacity(0.3),
                      width: 1.2,
                    ),
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
            style: const TextStyle(
              color: Colors.white,
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
                  color: const Color(0xFF27272A),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  widget.customerType,
                  style: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Gap(8),
              const Text(
                '·',
                style: TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Gap(8),
              Text(
                widget.sector,
                style: const TextStyle(
                  color: Color(0xFF9CA3AF),
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
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
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
