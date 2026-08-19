import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/constants/app_colors.dart';
import '../../core/database/app_database.dart';
import '../../core/providers/services_provider.dart';
import '../../shared/widgets/apex_card.dart';
import '../../shared/widgets/loading_shimmer.dart';
import '../../shared/widgets/apex_modal.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dash = ref.watch(dashboardProvider);

    return dash.when(
      loading: () => const LoadingShimmer(),
      error: (e, _) => Center(child: Text('$e')),
      data: (data) {
        final stockMax = [data.previousMonthStockIn, data.currentMonthStockIn, 1.0]
            .reduce((a, b) => a > b ? a : b);
        final salesMax = [data.previousMonthSales, data.currentMonthSales, 1.0]
            .reduce((a, b) => a > b ? a : b);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Owner Dashboard', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            const Text('Full shop overview — offline on this device',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                _metricCard('Total Items', '${data.totalItems} items', LucideIcons.package, AppColors.primary),
                _metricCard('Stock Value', null, LucideIcons.trendingUp, AppColors.success,
                    amount: data.totalStockValue),
                _metricCard('Sales This Month', null, LucideIcons.shoppingCart, AppColors.warning,
                    amount: data.currentMonthSales),
                _metricCard('Suppliers', '${data.totalSuppliers} suppliers', LucideIcons.truck, AppColors.accent),
              ],
            ),
            const SizedBox(height: 16),
            ApexCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Monthly Activity', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Stock-In Received', style: TextStyle(fontSize: 12)),
                      GhcText(data.currentMonthStockIn, bold: true, color: AppColors.success),
                    ],
                  ),
                  const SizedBox(height: 6),
                  GlowBar(value: data.currentMonthStockIn, max: stockMax, color: AppColors.success),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Sales / Dispatched', style: TextStyle(fontSize: 12)),
                      GhcText(data.currentMonthSales, bold: true, color: AppColors.warning),
                    ],
                  ),
                  const SizedBox(height: 6),
                  GlowBar(value: data.currentMonthSales, max: salesMax, color: AppColors.warning),
                  const SizedBox(height: 16),
                  if (data.lowStockItems.isNotEmpty)
                    InkWell(
                      onTap: () => _showLowStock(context, data.lowStockItems),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.dangerBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.danger.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.alertTriangle, color: AppColors.danger, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${data.lowStockItems.length} items running low — tap to view',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.danger,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    const Row(
                      children: [
                        Icon(Icons.check_circle, color: AppColors.success, size: 16),
                        SizedBox(width: 8),
                        Text('All stock levels healthy', style: TextStyle(fontSize: 12, color: AppColors.success)),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ApexCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Recent Deliveries', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (data.recentStockIns.isEmpty)
                    const Text('No deliveries yet', style: TextStyle(color: AppColors.textMuted))
                  else
                    ...data.recentStockIns.map(
                      (s) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(s.referenceNumber, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('${s.supplierName} · ${s.itemCount} lines'),
                        trailing: GhcText(s.totalCost, bold: true),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _metricCard(String label, String? text, IconData icon, Color color, {double? amount}) {
    return ApexCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const Spacer(),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          if (amount != null)
            GhcText(amount, bold: true)
          else
            Text(text!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  void _showLowStock(BuildContext context, List<Item> items) {
    showApexModal(
      context: context,
      title: 'Low Stock Items',
      subtitle: '${items.length} items at or below minimum',
      child: Column(
        children: items
            .map(
              (i) => ListTile(
                title: Text(i.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('Min: ${i.minThreshold} ${i.unit}'),
                trailing: Text(
                  '${i.quantity} ${i.unit}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: i.quantity == 0 ? AppColors.danger : AppColors.warning,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
