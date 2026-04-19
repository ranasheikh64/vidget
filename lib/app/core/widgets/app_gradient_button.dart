import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppGradientButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double? width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final LinearGradient gradient;

  const AppGradientButton({
    super.key,
    required this.child,
    this.onTap,
    this.width,
    this.height = 44,
    this.borderRadius = 12,
    this.padding,
    this.gradient = AppColors.primaryGradient,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}

class AppGradientIconButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback? onTap;
  final double size;
  final double borderRadius;

  const AppGradientIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 36,
    this.borderRadius = 50,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        alignment: Alignment.center,
        child: icon,
      ),
    );
  }
}
