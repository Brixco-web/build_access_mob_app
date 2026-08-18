import 'package:flutter/material.dart';

/// App color palette reflecting corporate slate aesthetics with modern accents.
abstract class AppColors {
  // Brand & Slate colors
  static const Color primary = Color(0xFF0F172A); // Slate 900
  static const Color primaryLight = Color(0xFF1E293B); // Slate 800
  static const Color background = Color(0xFFF8FAFC); // Slate 50
  static const Color surface = Colors.white;
  static const Color border = Color(0xFFE2E8F0); // Slate 200

  // Status & Financial colors
  static const Color success = Color(0xFF10B981); // Emerald 500 (Sales / In Stock)
  static const Color successBg = Color(0xFFECFDF5);
  static const Color warning = Color(0xFFF59E0B); // Amber 500 (Low Stock / Restocks)
  static const Color warningBg = Color(0xFFFFFBEB);
  static const Color danger = Color(0xFFEF4444); // Red 500 (Debt / Out of Stock)
  static const Color dangerBg = Color(0xFFFEF2F2);
  static const Color accent = Color(0xFF2563EB); // Blue 600
  static const Color accentBg = Color(0xFFEFF6FF);

  // Typography colors
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
}
