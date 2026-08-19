import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/auth_provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/security/biometric_service.dart';
import '../../core/security/pin_service.dart';
import '../../shared/widgets/apex_card.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;
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
    _biometricEnabled = await PinService.instance.isBiometricEnabled();
    _biometricAvailable = await BiometricService.instance.canCheckBiometrics();
    final db = ref.read(databaseProvider);
    final shopName = await db.getSetting('shopName') ?? 'Apex Building Accessories';
    _shopNameCtrl.text = shopName;
    if (mounted) setState(() => _shopLoaded = true);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Settings', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        const Text('Owner device settings — no staff management on mobile',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
        const SizedBox(height: 16),
        ApexCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Security', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Use fingerprint to unlock'),
                subtitle: _biometricAvailable
                    ? null
                    : const Text('Biometrics not available on this device'),
                value: _biometricEnabled,
                onChanged: _biometricAvailable
                    ? (v) async {
                        await PinService.instance.setBiometricEnabled(v);
                        setState(() => _biometricEnabled = v);
                      }
                    : null,
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Change PIN'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go('/lock?setup=1'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Lock app now'),
                trailing: const Icon(Icons.lock_outline),
                onTap: () {
                  ref.read(authProvider.notifier).lock();
                  context.go('/lock');
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
            children: const [
              Text('About', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('Apex Building Accessories — Offline Owner App'),
              Text('All data is stored locally on this device only.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            ],
          ),
        ),
      ],
    );
  }
}
