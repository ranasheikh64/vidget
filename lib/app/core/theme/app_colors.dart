import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Backgrounds
  static const Color bg = Color(0xFF0f0f13);
  static const Color bgCard = Color(0xFF1a1a24);
  static const Color bgInput = Color(0xFF1e1e2a);
  static const Color bgVault = Color(0xFF0a0a12);

  // Primary gradient colors
  static const Color violet = Color(0xFF8b5cf6);
  static const Color violetLight = Color(0xFFa78bfa);
  static const Color violetDark = Color(0xFF7c3aed);
  static const Color blue = Color(0xFF3b82f6);
  static const Color blueDark = Color(0xFF2563eb);

  // Status colors
  static const Color green = Color(0xFF10b981);
  static const Color amber = Color(0xFFf59e0b);
  static const Color red = Color(0xFFef4444);
  static const Color gray = Color(0xFF6b7280);

  // Text
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF9ca3af);
  static const Color textTertiary = Color(0xFF6b7280);

  // Borders
  static const Color border = Color(0x1AFFFFFF); // white/10
  static const Color borderSubtle = Color(0x14FFFFFF); // white/8

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [violet, blue],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient primaryGradientDiag = LinearGradient(
    colors: [violetDark, blueDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient greenGradient = LinearGradient(
    colors: [green, Color(0xFF059669)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Icon backgrounds
  static const Color iconBgViolet = Color(0x4D2d1f5e);
  static const Color iconBgBlue = Color(0x4D1e3a5f);
  static const Color iconBgGreen = Color(0x4D14432a);
  static const Color iconBgAmber = Color(0x4D422006);
  static const Color iconBgRed = Color(0x4D3b0a0a);
}
