import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme/oled_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Destinations
// ─────────────────────────────────────────────────────────────────────────────

/// A place in the app reachable from the navbar or sidebar.
///
/// [branchIndex] is the index of its StatefulShellBranch. Destinations
/// without a branch (e.g. Messages) are opened as a pushed screen and can't be
/// pinned to the bottom bar.
class AppDestination {
  final String id;
  final String label;
  final String subtitle;
  final IconData icon;
  final String path;
  final int? branchIndex;
  final Color tint;

  const AppDestination({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.path,
    required this.tint,
    this.branchIndex,
  });

  bool get isPinnable => branchIndex != null;
}

class AppDestinations {
  AppDestinations._();

  static const today = AppDestination(
    id: 'today',
    label: 'Today',
    subtitle: 'Sessions & daily focus',
    icon: LucideIcons.layoutGrid,
    path: '/today',
    branchIndex: 0,
    tint: OledTheme.accent,
  );
  static const skills = AppDestination(
    id: 'skills',
    label: 'Skills',
    subtitle: 'What you are learning',
    icon: LucideIcons.bookOpen,
    path: '/skills',
    branchIndex: 1,
    tint: OledTheme.cyan,
  );
  static const calendar = AppDestination(
    id: 'calendar',
    label: 'Calendar',
    subtitle: 'Plan your week',
    icon: LucideIcons.calendar,
    path: '/calendar',
    branchIndex: 2,
    tint: OledTheme.violet,
  );
  static const progress = AppDestination(
    id: 'progress',
    label: 'Progress',
    subtitle: 'Streaks & analytics',
    icon: LucideIcons.trendingUp,
    path: '/progress',
    branchIndex: 3,
    tint: OledTheme.amber,
  );
  static const notes = AppDestination(
    id: 'notes',
    label: 'Notes',
    subtitle: 'Personal learning notes',
    icon: LucideIcons.fileText,
    path: '/notes',
    branchIndex: 4,
    tint: OledTheme.cyan,
  );
  static const money = AppDestination(
    id: 'money',
    label: 'Money',
    subtitle: 'Expenses & budgets',
    icon: LucideIcons.wallet,
    path: '/money',
    branchIndex: 5,
    tint: OledTheme.emerald,
  );
  static const settings = AppDestination(
    id: 'settings',
    label: 'Settings',
    subtitle: 'Preferences & account',
    icon: LucideIcons.settings,
    path: '/settings',
    branchIndex: 6,
    tint: OledTheme.textSecondary,
  );
  static const messages = AppDestination(
    id: 'messages',
    label: 'Messages',
    subtitle: 'Private conversations',
    icon: LucideIcons.messageSquare,
    path: '/messages',
    tint: OledTheme.accent,
  );

  /// Sidebar order.
  static const all = <AppDestination>[
    today,
    skills,
    calendar,
    progress,
    notes,
    money,
    messages,
    settings,
  ];

  static const defaultPinned = <String>['today', 'skills', 'calendar', 'progress'];

  static const int minPinned = 2;
  static const int maxPinned = 4;

  static AppDestination? byId(String id) {
    for (final d in all) {
      if (d.id == id) return d;
    }
    return null;
  }

  static AppDestination? byBranch(int index) {
    for (final d in all) {
      if (d.branchIndex == index) return d;
    }
    return null;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Glass quality (keeps low-end devices smooth without removing animation)
// ─────────────────────────────────────────────────────────────────────────────

enum GlassMode { auto, full, lite }

/// Watches real frame timings for a short window after launch. If the device
/// struggles to hit 60 fps, the app swaps live backdrop blur (the single most
/// expensive effect) for an opaque graphite surface. Animations are untouched.
class DevicePerformance {
  DevicePerformance._();

  static final ValueNotifier<bool> isLowEnd = ValueNotifier<bool>(false);

  static bool _started = false;
  static int _seen = 0;
  static int _sampled = 0;
  static int _slow = 0;

  static void start() {
    if (_started) return;
    _started = true;
    try {
      SchedulerBinding.instance.addTimingsCallback(_onTimings);
    } catch (_) {}
  }

  static void _onTimings(List<FrameTiming> timings) {
    for (final t in timings) {
      _seen++;
      // Skip launch frames: shader warm-up and first layouts are always slow.
      if (_seen < 45) continue;
      _sampled++;
      final ms = (t.buildDuration + t.rasterDuration).inMicroseconds / 1000.0;
      if (ms > 16.0) _slow++;
    }
    if (_sampled >= 150) {
      // More than 1 in 5 frames over budget → treat as low-end.
      isLowEnd.value = _slow / _sampled > 0.20;
      SchedulerBinding.instance.removeTimingsCallback(_onTimings);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Preferences
// ─────────────────────────────────────────────────────────────────────────────

@immutable
class NavPrefs {
  final List<String> pinned;
  final GlassMode glassMode;

  const NavPrefs({
    this.pinned = AppDestinations.defaultPinned,
    this.glassMode = GlassMode.auto,
  });

  List<AppDestination> get pinnedDestinations => pinned
      .map(AppDestinations.byId)
      .whereType<AppDestination>()
      .where((d) => d.isPinnable)
      .toList(growable: false);

  NavPrefs copyWith({List<String>? pinned, GlassMode? glassMode}) => NavPrefs(
        pinned: pinned ?? this.pinned,
        glassMode: glassMode ?? this.glassMode,
      );
}

class NavPrefsNotifier extends StateNotifier<NavPrefs> {
  NavPrefsNotifier() : super(const NavPrefs()) {
    _load();
  }

  static const _kPinned = 'nav_pinned_tabs_v1';
  static const _kGlass = 'nav_glass_mode_v1';

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(_kPinned);
      final glass = prefs.getString(_kGlass);
      if (!mounted) return;
      final valid = saved
          ?.where((id) => AppDestinations.byId(id)?.isPinnable ?? false)
          .toSet()
          .toList();
      state = NavPrefs(
        pinned: (valid != null && valid.length >= AppDestinations.minPinned)
            ? valid.take(AppDestinations.maxPinned).toList()
            : AppDestinations.defaultPinned,
        glassMode: GlassMode.values.firstWhere(
          (m) => m.name == glass,
          orElse: () => GlassMode.auto,
        ),
      );
    } catch (_) {
      // Prefs unavailable (tests / first run) — defaults are fine.
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_kPinned, state.pinned);
      await prefs.setString(_kGlass, state.glassMode.name);
    } catch (_) {}
  }

  bool isPinned(String id) => state.pinned.contains(id);

  /// Returns false when the change would break the 2–4 pinned tab limits.
  bool togglePin(String id) {
    final dest = AppDestinations.byId(id);
    if (dest == null || !dest.isPinnable) return false;
    final next = [...state.pinned];
    if (next.contains(id)) {
      if (next.length <= AppDestinations.minPinned) return false;
      next.remove(id);
    } else {
      if (next.length >= AppDestinations.maxPinned) return false;
      next.add(id);
    }
    state = state.copyWith(pinned: next);
    _persist();
    return true;
  }

  void reorder(int oldIndex, int newIndex) {
    final next = [...state.pinned];
    if (oldIndex < 0 || oldIndex >= next.length) return;
    if (newIndex > oldIndex) newIndex -= 1;
    final item = next.removeAt(oldIndex);
    next.insert(newIndex.clamp(0, next.length), item);
    state = state.copyWith(pinned: next);
    _persist();
  }

  void resetPinned() {
    state = state.copyWith(pinned: AppDestinations.defaultPinned);
    _persist();
  }

  void setGlassMode(GlassMode mode) {
    state = state.copyWith(glassMode: mode);
    _persist();
  }
}

final navPrefsProvider =
    StateNotifierProvider<NavPrefsNotifier, NavPrefs>((ref) => NavPrefsNotifier());
