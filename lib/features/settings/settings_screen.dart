import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/database_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../shared/widgets/apex_card.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _shopNameCtrl = TextEditingController();
  bool _shopLoaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _shopNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final db = ref.read(databaseProvider);
    final shopName = await db.getSetting('shopName') ?? 'Apex Building Accessories';
    _shopNameCtrl.text = shopName;
    if (mounted) setState(() => _shopLoaded = true);
  }

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Settings', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          'Owner device settings — no staff management on mobile',
          style: TextStyle(color: muted, fontSize: 13),
        ),
        const SizedBox(height: 16),
        ApexCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Appearance', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Dark mode'),
                subtitle: const Text('Easier on the eyes in low light'),
                value: isDark,
                onChanged: (enabled) {
                  ref.read(themeModeProvider.notifier).setDarkMode(enabled);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ApexCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Shop', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (!_shopLoaded)
                const LinearProgressIndicator()
              else ...[
                TextField(
                  controller: _shopNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Shop display name',
                    helperText: 'Shown on receipts and reports',
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: () async {
                      final db = ref.read(databaseProvider);
                      await db.setSetting('shopName', _shopNameCtrl.text.trim());
                      ref.invalidate(shopNameProvider);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Shop name saved')),
                      );
                    },
                    child: const Text('Save shop name'),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        ApexCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('About', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Apex Building Accessories — Offline Owner App'),
              Text(
                'All data is stored locally on this device only.',
                style: TextStyle(fontSize: 12, color: muted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
