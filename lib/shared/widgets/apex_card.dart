import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';

class ApexCard extends StatelessWidget {
  const ApexCard({super.key, required this.child, this.padding = const EdgeInsets.all(16)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: child,
    );
  }
}

class GhcText extends StatelessWidget {
  const GhcText(
    this.amount, {
    super.key,
    this.style,
    this.bold = false,
    this.color,
  });

  final double amount;
  final TextStyle? style;
  final bool bold;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      CurrencyFormatter.format(amount),
      style: (style ?? Theme.of(context).textTheme.bodyMedium)?.copyWith(
            fontFamily: 'monospace',
            fontWeight: bold ? FontWeight.bold : FontWeight.w600,
            color: color,
          ),
    );
  }
}

class GlowBar extends StatelessWidget {
  const GlowBar({super.key, required this.value, required this.max, required this.color});

  final double value;
  final double max;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final pct = max > 0 ? (value / max).clamp(0.0, 1.0) : 0.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: pct,
        minHeight: 12,
        backgroundColor: Colors.grey.shade100,
        color: color,
      ),
    );
  }
}
