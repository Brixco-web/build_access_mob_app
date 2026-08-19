import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthState {
  const AuthState({required this.isUnlocked, required this.hasPinSetup});

  final bool isUnlocked;
  final bool hasPinSetup;

  AuthState copyWith({bool? isUnlocked, bool? hasPinSetup}) {
    return AuthState(
      isUnlocked: isUnlocked ?? this.isUnlocked,
      hasPinSetup: hasPinSetup ?? this.hasPinSetup,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState(isUnlocked: false, hasPinSetup: false));

  void unlock() => state = state.copyWith(isUnlocked: true);
  void lock() => state = state.copyWith(isUnlocked: false);
  void setHasPinSetup(bool value) => state = state.copyWith(hasPinSetup: value);
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
