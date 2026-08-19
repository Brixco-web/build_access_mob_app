import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/database/enums.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge._({required this.label, required this.color, this.bg});

  final String label;
  final Color color;
  final Color? bg;

  factory StatusBadge.order(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return StatusBadge._(label: 'Pending', color: const Color(0xFFD97706), bg: const Color(0xFFFFFBEB));
      case OrderStatus.partiallyReceived:
        return StatusBadge._(label: 'Partial', color: const Color(0xFF2563EB), bg: const Color(0xFFEFF6FF));
      case OrderStatus.received:
        return StatusBadge._(label: 'Received', color: AppColors.success, bg: AppColors.successBg);
      case OrderStatus.cancelled:
        return StatusBadge._(label: 'Cancelled', color: AppColors.textMuted, bg: const Color(0xFFF1F5F9));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg ?? color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
    );
  }
}
