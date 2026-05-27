import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final double iconSize;
  final BorderRadius? borderRadius;
  final bool withShadow;

  const AppLogo({
    super.key,
    this.size = 40,
    double? iconSize,
    this.borderRadius,
    this.withShadow = false,
  }) : iconSize = iconSize ?? size * 0.5;

  static const IconData icon = Icons.shield;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).primaryColor;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: borderRadius ?? BorderRadius.circular(size * 0.22),
        boxShadow: withShadow
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.35),
                  blurRadius: size * 0.22,
                  offset: Offset(0, size * 0.1),
                ),
              ]
            : null,
      ),
      child: Icon(icon, color: Colors.white, size: iconSize),
    );
  }
}
