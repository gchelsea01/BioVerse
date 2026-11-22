import 'package:flutter/foundation.dart';

/// Bottom-navigation tab indices, so screens can jump between tabs.
enum AppTab { home, donate, pet, profile }

class ShellController extends ValueNotifier<AppTab> {
  ShellController() : super(AppTab.home);

  void go(AppTab tab) => value = tab;
}
