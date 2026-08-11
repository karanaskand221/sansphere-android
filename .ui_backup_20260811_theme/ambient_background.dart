import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AmbientBackground extends StatelessWidget {
  final Widget child;

  const AmbientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: AppColors.background),

        Positioned(
          top: -180,
          left: -120,
          child: _orb(
            size: 420,
            color: AppColors.purple.withValues(alpha: 0.18),
          ),
        ),

        Positioned(
          top: 180,
          right: -180,
          child: _orb(size: 420, color: AppColors.cyan.withValues(alpha: 0.13)),
        ),

        Positioned(
          bottom: -220,
          left: 80,
          child: _orb(
            size: 460,
            color: AppColors.purpleDark.withValues(alpha: 0.11),
          ),
        ),

        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
            child: const SizedBox.expand(),
          ),
        ),

        child,
      ],
    );
  }

  Widget _orb({required double size, required Color color}) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}
