import 'package:flutter/material.dart';

/// Reusable hover & float animation container for cards, tiles, and interactive sections.
class VernexaFloatable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double hoverOffset;
  final double hoverElevation;
  final double scale;
  final Duration duration;
  final BorderRadius? borderRadius;

  const VernexaFloatable({
    super.key,
    required this.child,
    this.onTap,
    double? hoverOffset,
    double? translateY,
    this.hoverElevation = 8.0,
    this.scale = 1.0,
    this.duration = const Duration(milliseconds: 180),
    this.borderRadius,
  }) : hoverOffset = translateY ?? hoverOffset ?? -4.0;

  @override
  State<VernexaFloatable> createState() => _VernexaFloatableState();
}

class _VernexaFloatableState extends State<VernexaFloatable> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final yOffset = _isHovered ? widget.hoverOffset : 0.0;

    return MouseRegion(
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: widget.duration,
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0.0, yOffset, 0.0),
          decoration: widget.borderRadius != null && _isHovered && widget.hoverElevation > 0
              ? BoxDecoration(
                  borderRadius: widget.borderRadius,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: widget.hoverElevation * 1.5,
                      offset: Offset(0, widget.hoverElevation * 0.7),
                    ),
                  ],
                )
              : null,
          child: widget.child,
        ),
      ),
    );
  }
}
