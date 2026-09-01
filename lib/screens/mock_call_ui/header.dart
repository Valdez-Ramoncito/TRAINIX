import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:trainixprogram/components/animation_effect/hover_button.dart';
import 'package:trainixprogram/components/size.dart';

class Header extends StatelessWidget {
  final String sector;
  final int completedInteractions;
  final int requiredInteractions;
  final VoidCallback? onDebugFinish;
  final VoidCallback? onToggleTheme;
  final VoidCallback? onOpenSettings;

  const Header({
    super.key,
    required this.sector,
    required this.completedInteractions,
    required this.requiredInteractions,
    this.onDebugFinish,
    this.onToggleTheme,
    this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Current customer number (1-indexed for display, capped at requiredInteractions)
    final int currentCustomerNum = (completedInteractions + 1).clamp(
      1,
      requiredInteractions > 0 ? requiredInteractions : 1,
    );

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF27272A) : const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left side: Sector pill tag
          Row(
            children: [
              Text(
                "Mock Call Simulation",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: context.responsiveFont(6),
                ),
              ),
              Gap(10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFDCEBFE),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF3B82F6).withOpacity(0.6)
                        : const Color(0xFF93C5FD),
                    width: 1.2,
                  ),
                ),
                child: Text(
                  sector.toUpperCase(),
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFF60A5FA)
                        : const Color(0xFF2563EB),
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          // Right side: Customer tracker, Stepper dots, and Action toolbar icons
          Row(
            children: [
              // "Customer" label
              Text(
                'Customer',
                style: TextStyle(
                  color: isDark
                      ? const Color(0xFF9CA3AF)
                      : const Color(0xFF6B7280),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const Gap(8),

              // Customer count box
              Container(
                width: 48,
                height: 28,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF27272A)
                      : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white12),
                ),
                child: Center(
                  child: Text(
                    '$currentCustomerNum / $requiredInteractions',
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFFF3F4F6)
                          : const Color(0xFF374151),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const Gap(16),

              // Step indicator dots
              Row(
                children: List.generate(
                  requiredInteractions > 0 ? requiredInteractions : 5,
                  (index) {
                    final bool isActive = index < currentCustomerNum;
                    return Container(
                      margin: const EdgeInsets.only(right: 6),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive
                            ? (isDark
                                  ? const Color(0xFF3B82F6)
                                  : const Color(0xFF2563EB))
                            : (isDark
                                  ? const Color(0xFF4B5563)
                                  : const Color(0xFFD1D5DB)),
                      ),
                    );
                  },
                ),
              ),
              const Gap(20),

              // Action Toolbar Icons
              if (onDebugFinish != null) ...[
                ToolbarIcon(
                  icon: Icons.fast_forward_outlined,
                  tooltip: 'Finish Simulation (debug)',
                  onTap: onDebugFinish,
                ),
                const Gap(4),
              ],
              ToolbarIcon(
                icon: Icons.wb_sunny_outlined,
                tooltip: 'Light mode',
                onTap: onToggleTheme,
              ),
              const Gap(4),
              ToolbarIcon(
                icon: Icons.settings_outlined,
                tooltip: 'Call Settings',
                onTap: onOpenSettings,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
