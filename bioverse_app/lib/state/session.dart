import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/gamification.dart';
import '../models/user.dart';
import 'services.dart';

enum SessionStatus { loading, onboarding, signedOut, signedIn }

/// Who is logged in plus the small bits of state shown on many screens
/// (points, streak, primary pet). Screens call the refresh methods after
/// actions that change them.
class Session extends ChangeNotifier {
  Session(this.services) {
    services.api.onSessionExpired = () {
      _clear();
      status = SessionStatus.signedOut;
      notifyListeners();
    };
  }

  final Services services;
  static const _onboardingKey = 'onboarding_done';

  SessionStatus status = SessionStatus.loading;
  UserProfile? user;
  VirtualPet? pet;
  Streak streak = const Streak();
  bool petLoaded = false;

  int get points => user?.points ?? 0;

  Future<void> bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    await services.api.tokens.load();
    if (services.api.tokens.hasSession) {
      try {
        user = await services.user.me();
        status = SessionStatus.signedIn;
        notifyListeners();
        refreshGame();
        return;
      } catch (_) {
        // Expired or offline: fall through to login.
      }
    }
    status = (prefs.getBool(_onboardingKey) ?? false) ? SessionStatus.signedOut : SessionStatus.onboarding;
    notifyListeners();
  }

  Future<void> finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
    status = SessionStatus.signedOut;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    final result = await services.auth.login(email, password);
    await _signedIn(result.user);
  }

  Future<void> register({required String fullName, required String email, required String password, String? referral}) async {
    final result = await services.auth.register(
      fullName: fullName,
      email: email,
      password: password,
      referralCode: referral,
    );
    await _signedIn(result.user);
  }

  Future<void> _signedIn(UserProfile? fromAuth) async {
    user = fromAuth ?? await services.user.me();
    status = SessionStatus.signedIn;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
    notifyListeners();
    refreshGame();
  }

  Future<void> logout() async {
    try {
      await services.auth.logout();
    } catch (_) {
      // Tokens are cleared regardless.
    }
    _clear();
    status = SessionStatus.signedOut;
    notifyListeners();
  }

  void _clear() {
    user = null;
    pet = null;
    petLoaded = false;
    streak = const Streak();
  }

  Future<void> refreshUser() async {
    try {
      user = await services.user.me();
      notifyListeners();
    } catch (_) {}
  }

  void setUser(UserProfile value) {
    user = value;
    notifyListeners();
  }

  void setPoints(int balance) {
    user = user?.copyWith(points: balance);
    notifyListeners();
  }

  /// Loads pet and streak; failures leave the previous values.
  Future<void> refreshGame() async {
    await Future.wait([refreshPet(), refreshStreak()]);
  }

  Future<void> refreshPet() async {
    try {
      final pets = await services.game.pets();
      pet = pets.isEmpty ? null : pets.firstWhere((p) => p.isPrimary, orElse: () => pets.first);
    } catch (_) {}
    petLoaded = true;
    notifyListeners();
  }

  void setPet(VirtualPet value) {
    pet = value;
    petLoaded = true;
    notifyListeners();
  }

  Future<void> refreshStreak() async {
    try {
      streak = await services.game.streak();
      notifyListeners();
    } catch (_) {}
  }
}
