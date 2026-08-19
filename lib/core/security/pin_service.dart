import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PinService {
  PinService._();
  static final PinService instance = PinService._();

  static const _storage = FlutterSecureStorage();
  static const _pinHashKey = 'owner_pin_hash';
  static const _biometricKey = 'biometric_enabled';

  String _hashPin(String pin) {
    final bytes = utf8.encode('apex_salt_$pin');
    return sha256.convert(bytes).toString();
  }

  Future<bool> hasPin() async {
    final hash = await _storage.read(key: _pinHashKey);
    return hash != null && hash.isNotEmpty;
  }

  Future<void> setPin(String pin) async {
    if (pin.length < 4) throw ArgumentError('PIN must be at least 4 digits');
    await _storage.write(key: _pinHashKey, value: _hashPin(pin));
  }

  Future<bool> verifyPin(String pin) async {
    final stored = await _storage.read(key: _pinHashKey);
    if (stored == null) return false;
    return stored == _hashPin(pin);
  }

  Future<bool> isBiometricEnabled() async {
    return (await _storage.read(key: _biometricKey)) == 'true';
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(key: _biometricKey, value: enabled ? 'true' : 'false');
  }
}
