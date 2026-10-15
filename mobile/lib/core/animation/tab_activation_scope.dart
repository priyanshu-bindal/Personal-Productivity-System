import 'package:flutter/material.dart';

/// Notifies descendants of the currently active navigation tab index
/// and an activation tick that increments whenever a tab is switched or returned to.
class TabActivationScope extends InheritedWidget {
  /// The currently active branch/tab index (0: Today, 1: Skills, 2: Calendar, 3: Progress, etc.)
  final int activeTabIndex;

  /// Monotonically increasing tick counter. Increments on every tab switch or route pop.
  final int activationTick;

  const TabActivationScope({
    super.key,
    required this.activeTabIndex,
    required this.activationTick,
    required super.child,
  });

  static TabActivationScope? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<TabActivationScope>();
  }

  @override
  bool updateShouldNotify(TabActivationScope oldWidget) {
    return oldWidget.activeTabIndex != activeTabIndex ||
        oldWidget.activationTick != activationTick;
  }
}

/// Injected at the root of each tab screen to identify which tab index this screen represents.
class TabCardScope extends InheritedWidget {
  /// The tab index this subtree belongs to (0: Today, 1: Skills, 2: Calendar, 3: Progress).
  final int tabIndex;

  const TabCardScope({
    super.key,
    required this.tabIndex,
    required super.child,
  });

  static TabCardScope? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<TabCardScope>();
  }

  @override
  bool updateShouldNotify(TabCardScope oldWidget) {
    return oldWidget.tabIndex != tabIndex;
  }
}
