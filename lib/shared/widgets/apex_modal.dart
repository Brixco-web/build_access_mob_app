import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

Future<T?> showApexModal<T>({
  required BuildContext context,
  required String title,
  String? subtitle,
  required Widget child,
  List<Widget>? actions,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: Theme.of(context).textTheme.titleMedium),
                        if (subtitle != null)
                          Text(subtitle, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                child: child,
              ),
            ),
            if (actions != null && actions.isNotEmpty)
              Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(ctx).padding.bottom + 16),
                child: Row(children: actions),
              ),
          ],
        ),
      ),
    ),
  );
}
