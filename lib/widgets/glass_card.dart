import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class GlassCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;
  final bool active;
  final double radius;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.onTap,
    this.active = false,
    this.radius = 20,
  });

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      transform: Matrix4.translationValues(
        0,
        _pressed ? 1.5 : 0,
        0,
      ),
      padding: widget.padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(widget.radius),
        border: Border.all(
          color: widget.active
              ? AppColors.activeBorder
              : AppColors.border,
          width: widget.active ? 1.4 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: _pressed ? 0.06 : 0.045,
            ),
            blurRadius: _pressed ? 8 : 16,
            offset: Offset(
              0,
              _pressed ? 3 : 6,
            ),
          ),
        ],
      ),
      child: widget.child,
    );

    final result = widget.onTap == null
        ? card
        : GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onTap,
            onTapDown: (_) {
              setState(() => _pressed = true);
            },
            onTapCancel: () {
              setState(() => _pressed = false);
            },
            onTapUp: (_) {
              setState(() => _pressed = false);
            },
            child: card,
          );

    return Padding(
      padding: widget.margin,
      child: result,
    );
  }
}
