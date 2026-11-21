import 'package:flutter/material.dart';
import 'package:trainixprogram/components/app_colors.dart';

class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffold = AppColors.scaffold(context);

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: scaffold,
        image: DecorationImage(
          image: AssetImage(
            isDark
                ? 'assets/images/background.png'
                : 'assets/images/background_light.png',
          ),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (!isDark) ...[
            // Daylight atmosphere: brand green top-left, blue bottom-right.
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-0.9, -0.95),
                    radius: 1.25,
                    colors: [
                      AppColors.atmospherePrimary(context),
                      scaffold.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.95, 0.9),
                    radius: 1.15,
                    colors: [
                      AppColors.atmosphereSecondary(context),
                      scaffold.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ],
          ColoredBox(
            color: scaffold.withValues(alpha: isDark ? 0.55 : 0.24),
            child: child,
          ),
        ],
      ),
    );
  }
}
