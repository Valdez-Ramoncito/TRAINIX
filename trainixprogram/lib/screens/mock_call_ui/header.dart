import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:trainixprogram/components/button/toolbar_button.dart';
import 'package:trainixprogram/components/size.dart';
import 'package:trainixprogram/models/simulation_phase.dart';
import 'package:trainixprogram/models/trainix_debug.dart';

class Header extends StatelessWidget {
  final String sector;
  final SimulationMode mode;
  final int completedInteractions;
  final int requiredInteractions;
  final VoidCallback? onDebugFinish;
  final VoidCallback? onOpenSettings;

  const Header({
    super.key,
    required this.sector,
    this.mode = SimulationMode.chat,
    required this.completedInteractions,
    required this.requiredInteractions,
    this.onDebugFinish,
    this.onOpenSettings,
  });

  String get _title {
    switch (mode) {
      case SimulationMode.chat:
        return 'Non-Voice Session';
      case SimulationMode.voice:
        return 'Voice Session';
    }
  }

  @override
  Widget build(BuildContext context) {
    final int currentCustomerNum = (completedInteractions + 1).clamp(
      1,
      requiredInteractions > 0 ? requiredInteractions : 1,
    );

    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color.fromARGB(255, 105, 106, 106),
            width: 0.3,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                _title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: context.responsiveFont(6),
                ),
              ),
              const Gap(10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 21, 44, 76),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color.fromARGB(255, 130, 174, 240),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  sector.toUpperCase(),
                  style: const TextStyle(
                    color: Color.fromARGB(255, 160, 200, 255),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              const Text(
                'Customer',
                style: TextStyle(
                  color: Color(0xFFB0B8C4),
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const Gap(8),
              Container(
                width: 52,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(180, 21, 21, 21),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: const Color.fromARGB(255, 49, 48, 48),
                    width: 0.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    '$currentCustomerNum / $requiredInteractions',
                    style: const TextStyle(
                      color: Color(0xFFE5E7EB),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const Gap(12),
              Row(
                children: List.generate(requiredInteractions.clamp(1, 8), (i) {
                  final filled = i < completedInteractions;
                  return Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled
                          ? const Color.fromARGB(255, 112, 189, 138)
                          : const Color.fromARGB(255, 49, 48, 48),
                    ),
                  );
                }),
              ),
              const Gap(12),
              if (TrainixDebug.unlocked && onDebugFinish != null) ...[
                ToolbarIcon(
                  icon: Icons.fast_forward_outlined,
                  tooltip: 'Finish Simulation (debug)',
                  onTap: onDebugFinish,
                ),
                const Gap(4),
              ],
              ToolbarIcon(
                icon: Icons.settings_outlined,
                tooltip: 'Settings',
                onTap: onOpenSettings,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
