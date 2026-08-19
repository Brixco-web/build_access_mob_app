import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/security/biometric_service.dart';
import '../../core/security/pin_service.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key, this.setupMode = false});

  final bool setupMode;

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final hasPin = await PinService.instance.hasPin();
    ref.read(authProvider.notifier).setHasPinSetup(hasPin);
    _biometricAvailable = await BiometricService.instance.canCheckBiometrics();
    _biometricEnabled = await PinService.instance.isBiometricEnabled();
    if (!widget.setupMode && hasPin && _biometricEnabled) {
      await _tryBiometric();
    }
  }

  Future<void> _tryBiometric() async {
    final ok = await BiometricService.instance.authenticate();
    if (ok && mounted) {
      ref.read(authProvider.notifier).unlock();
      context.go('/');
    }
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (widget.setupMode || !(await PinService.instance.hasPin())) {
        if (_pinController.text.length < 4) {
          setState(() => _error = 'PIN must be at least 4 digits');
          return;
        }
        if (_pinController.text != _confirmController.text) {
          setState(() => _error = 'PINs do not match');
          return;
        }
        await PinService.instance.setPin(_pinController.text);
        if (_biometricAvailable) {
          await PinService.instance.setBiometricEnabled(true);
        }
        ref.read(authProvider.notifier).setHasPinSetup(true);
        ref.read(authProvider.notifier).unlock();
        if (mounted) context.go('/');
      } else {
        final ok = await PinService.instance.verifyPin(_pinController.text);
        if (ok) {
          ref.read(authProvider.notifier).unlock();
          if (mounted) context.go('/');
        } else {
          setState(() => _error = 'Incorrect PIN');
        }
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSetup = widget.setupMode || !ref.watch(authProvider).hasPinSetup;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Icon(Icons.storefront, size: 64, color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                isSetup ? 'Set up owner PIN' : 'Apex Building Accessories',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                isSetup
                    ? 'Create a PIN to secure your offline shop data'
                    : 'Enter PIN or use fingerprint to unlock',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'PIN',
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              if (isSetup) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _confirmController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Confirm PIN',
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: AppColors.danger)),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(isSetup ? 'Create PIN' : 'Unlock'),
              ),
              if (!isSetup && _biometricEnabled) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _tryBiometric,
                  icon: const Icon(Icons.fingerprint),
                  label: const Text('Use fingerprint'),
                ),
              ],
              const Spacer(flex: 2),
              const Text(
                'Offline owner app — data stays on this device',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
