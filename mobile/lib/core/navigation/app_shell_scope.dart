import 'package:flutter/widgets.dart';

/// Exposes shell-level actions (like opening the sidebar) to any screen that
/// lives inside the main navigation shell.
class AppShellScope extends InheritedWidget {
  final VoidCallback openSidebar;
  final VoidCallback closeSidebar;

  const AppShellScope({
    super.key,
    required this.openSidebar,
    required this.closeSidebar,
    required super.child,
  });

  static AppShellScope? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppShellScope>();

  @override
  bool updateShouldNotify(AppShellScope oldWidget) => false;
}
