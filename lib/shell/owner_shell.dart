import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../core/constants/app_colors.dart';
import '../core/providers/database_provider.dart';

class OwnerShell extends ConsumerStatefulWidget {
  const OwnerShell({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<OwnerShell> createState() => _OwnerShellState();
}

class _OwnerShellState extends ConsumerState<OwnerShell> {
  bool _moreOpen = false;

  static const _primaryTabs = [
    _Tab('/', 'Home', LucideIcons.layoutDashboard),
    _Tab('/inventory', 'Inventory', LucideIcons.boxes),
    _Tab('/sales', 'Sales', LucideIcons.shoppingCart),
    _Tab('/financial', 'Financial', LucideIcons.dollarSign),
  ];

  static const _moreItems = [
    _Tab('/orders', 'Orders', LucideIcons.packagePlus),
    _Tab('/activity-logs', 'Activity Logs', LucideIcons.clipboardList),
    _Tab('/suppliers', 'Suppliers', LucideIcons.truck),
    _Tab('/settings', 'Settings', LucideIcons.settings),
  ];

  String get _location => GoRouterState.of(context).uri.path;

  bool _isActive(String path) => _location == path || _location.startsWith('$path/');

  @override
  Widget build(BuildContext context) {
    final moreActive = _moreItems.any((t) => _isActive(t.path));
    final shopName = ref.watch(shopNameProvider).value ?? 'Apex Building Accessories';
    final titleParts = _splitShopTitle(shopName);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titleParts.$1, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            if (titleParts.$2.isNotEmpty)
              Text(titleParts.$2, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.normal)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.settings, size: 20),
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: widget.child,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_moreOpen)
            Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12)],
              ),
              child: Column(
                children: _moreItems
                    .map(
                      (item) => ListTile(
                        dense: true,
                        leading: Icon(item.icon, size: 18),
                        title: Text(item.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                        selected: _isActive(item.path),
                        onTap: () {
                          setState(() => _moreOpen = false);
                          context.go(item.path);
                        },
                      ),
                    )
                    .toList(),
              ),
            ),
          Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.border),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, -4))],
            ),
            child: Row(
              children: [
                ..._primaryTabs.map((tab) => Expanded(child: _tabButton(tab))),
                Expanded(
                  child: _moreButton(moreActive),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  (String, String) _splitShopTitle(String name) {
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.length <= 2) return (name, '');
    final mid = (words.length / 2).ceil();
    return (words.sublist(0, mid).join(' '), words.sublist(mid).join(' '));
  }

  Widget _tabButton(_Tab tab) {
    final active = _isActive(tab.path);
    return InkWell(
      onTap: () {
        setState(() => _moreOpen = false);
        context.go(tab.path);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(tab.icon, size: 20, color: active ? Colors.white : AppColors.textMuted),
            const SizedBox(height: 2),
            Text(
              tab.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: active ? Colors.white : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _moreButton(bool active) {
    return InkWell(
      onTap: () => setState(() => _moreOpen = !_moreOpen),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: _moreOpen || active ? AppColors.primary : AppColors.warning,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_moreOpen ? LucideIcons.x : LucideIcons.layoutGrid, size: 20, color: Colors.white),
            const SizedBox(height: 2),
            Text(
              _moreOpen ? 'Close' : 'More',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tab {
  const _Tab(this.path, this.label, this.icon);
  final String path;
  final String label;
  final IconData icon;
}
