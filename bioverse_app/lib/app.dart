import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/login_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/onboarding/splash_screen.dart';
import 'features/shell/main_shell.dart';
import 'features/shell/shell_controller.dart';
import 'state/services.dart';
import 'state/session.dart';

class BioVerseApp extends StatelessWidget {
  const BioVerseApp({super.key, required this.services});
  final Services services;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<Services>.value(value: services),
        ChangeNotifierProvider(create: (_) => Session(services)..bootstrap()),
        ChangeNotifierProvider(create: (_) => ShellController()),
      ],
      child: MaterialApp(
        title: 'BioVerse',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const _RootGate(),
      ),
    );
  }
}

/// Picks the first screen from the session status. Switching status (login,
/// logout, expired token) swaps the whole tree.
class _RootGate extends StatefulWidget {
  const _RootGate();

  @override
  State<_RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<_RootGate> {
  SessionStatus? _previous;

  @override
  Widget build(BuildContext context) {
    final status = context.select<Session, SessionStatus>((s) => s.status);
    if (_previous == SessionStatus.signedIn && status == SessionStatus.signedOut) {
      // Logged out or session expired mid-flow: close leftover screens and
      // start from Home next time.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).popUntil((r) => r.isFirst);
        context.read<ShellController>().go(AppTab.home);
      });
    }
    _previous = status;
    final child = switch (status) {
      SessionStatus.loading => const SplashScreen(),
      SessionStatus.onboarding => const OnboardingScreen(),
      SessionStatus.signedOut => const LoginScreen(),
      SessionStatus.signedIn => const MainShell(),
    };
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: KeyedSubtree(key: ValueKey(status), child: child),
    );
  }
}
