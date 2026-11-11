import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../core/animation/tab_activation_scope.dart';
import '../core/navigation/app_shell_scope.dart';
import '../core/theme/app_motion.dart';
import '../core/theme/oled_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/nav_prefs_provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/floating_dock.dart';
import 'app_router.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Layout constants & helpers (public — screens use these for bottom padding)
// ─────────────────────────────────────────────────────────────────────────────

/// Height of the floating glass capsule (without bottom safe-area inset).
const double _kNavBarHeight = 64.0;

/// Gap between the capsule and the safe-area bottom edge.
const double _kNavBarBottomMargin = 10.0;

/// Distance from the bottom of the screen to the bottom of the navbar.
double getFloatingNavBarBottom(BuildContext context) {
  final mq = MediaQuery.of(context);
  final systemBottomInset = math.max(mq.padding.bottom, mq.viewPadding.bottom);
  return math.max(systemBottomInset, 10.0) + _kNavBarBottomMargin;
}

/// Bottom clearance scrolling content needs so nothing hides behind the bar.
double getNavBarClearance(BuildContext context) {
  return getFloatingNavBarBottom(context) + _kNavBarHeight + 12.0;
}

/// Wraps a tab whose screen isn't navbar-aware: reports the navbar as bottom
/// safe-area so its SafeArea, lists and FAB sit above the floating capsule.
class NavBarSafeInset extends StatelessWidget {
  final Widget child;
  const NavBarSafeInset({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    if (mq.viewInsets.bottom > 80) return child; // navbar hides with keyboard
    final clearance = getNavBarClearance(context) - 8;
    return MediaQuery(
      data: mq.copyWith(
        padding: mq.padding.copyWith(bottom: math.max(mq.padding.bottom, clearance)),
        viewPadding:
            mq.viewPadding.copyWith(bottom: math.max(mq.viewPadding.bottom, clearance)),
      ),
      child: child,
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  AnimatedBranchContainer — smooth cross-fade between tabs
// ═════════════════════════════════════════════════════════════════════════════

/// Keeps every visited tab alive (like IndexedStack) but fades + lifts the
/// incoming tab over the outgoing one. Only the incoming tab animates, using
/// opacity + translate, so the cost is one composited layer for ~280ms.
/// Hidden tabs are offstage with tickers paused, so they cost nothing.
class AnimatedBranchContainer extends StatefulWidget {
  final int currentIndex;
  final List<Widget> children;

  const AnimatedBranchContainer({
    super.key,
    required this.currentIndex,
    required this.children,
  });

  @override
  State<AnimatedBranchContainer> createState() => _AnimatedBranchContainerState();
}

class _AnimatedBranchContainerState extends State<AnimatedBranchContainer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _lift;
  late int _current;
  int? _previous;

  @override
  void initState() {
    super.initState();
    _current = widget.currentIndex;
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.standard,
      value: 1.0,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && _previous != null && mounted) {
          setState(() => _previous = null);
        }
      });
    final curved = CurvedAnimation(parent: _controller, curve: AppMotion.enter);
    _fade = curved;
    _lift = Tween<Offset>(begin: const Offset(0, 0.012), end: Offset.zero).animate(curved);
  }

  @override
  void didUpdateWidget(AnimatedBranchContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != _current) {
      _previous = _current;
      _current = widget.currentIndex;
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = <int>[
      for (var i = 0; i < widget.children.length; i++)
        if (i != _current && i != _previous) i,
      if (_previous != null && _previous! < widget.children.length) _previous!,
      _current,
    ];

    return Stack(
      fit: StackFit.expand,
      children: [
        for (final i in order)
          _BranchSlot(
            key: ValueKey<int>(i),
            visible: i == _current || i == _previous,
            animate: i == _current && _previous != null,
            fade: _fade,
            lift: _lift,
            child: widget.children[i],
          ),
      ],
    );
  }
}

class _BranchSlot extends StatelessWidget {
  final bool visible;
  final bool animate;
  final Animation<double> fade;
  final Animation<Offset> lift;
  final Widget child;

  const _BranchSlot({
    super.key,
    required this.visible,
    required this.animate,
    required this.fade,
    required this.lift,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Structure is identical in every state so branch state is never lost.
    return Offstage(
      offstage: !visible,
      child: TickerMode(
        enabled: visible,
        child: IgnorePointer(
          ignoring: !visible,
          child: FadeTransition(
            opacity: animate ? fade : kAlwaysCompleteAnimation,
            child: SlideTransition(
              position: animate ? lift : const AlwaysStoppedAnimation(Offset.zero),
              child: RepaintBoundary(child: child),
            ),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  ScaffoldWithNavBar — the app shell
// ═════════════════════════════════════════════════════════════════════════════

class ScaffoldWithNavBar extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNavBar({super.key, required this.navigationShell});

  @override
  ConsumerState<ScaffoldWithNavBar> createState() => _ScaffoldWithNavBarState();
}

class _ScaffoldWithNavBarState extends ConsumerState<ScaffoldWithNavBar>
    with TickerProviderStateMixin, RouteAware {
  int _activationTick = 0;
  int _lastIndex = -1;

  late final AnimationController _sidebar;
  late final AnimationController _entrance;
  late final Animation<Offset> _navEntrance;
  late final Animation<double> _navEntranceFade;

  final ValueNotifier<bool> _sidebarOpen = ValueNotifier<bool>(false);
  double _sidebarWidth = 300;

  @override
  void initState() {
    super.initState();
    DevicePerformance.start();

    _sidebar = AnimationController(
      vsync: this,
      duration: AppMotion.emphasized,
      reverseDuration: AppMotion.standard,
    )..addStatusListener((s) {
        _sidebarOpen.value = s != AnimationStatus.dismissed;
      });

    _entrance = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
    final entranceCurve = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.2, 1.0, curve: AppMotion.enter),
    );
    _navEntrance = Tween<Offset>(begin: const Offset(0, 0.6), end: Offset.zero)
        .animate(entranceCurve);
    _navEntranceFade = entranceCurve;
    _entrance.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final modalRoute = ModalRoute.of(context);
    if (modalRoute != null) appRouteObserver.subscribe(this, modalRoute);
  }

  @override
  void didPopNext() {
    super.didPopNext();
    setState(() => _activationTick++);
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    _sidebar.dispose();
    _entrance.dispose();
    _sidebarOpen.dispose();
    super.dispose();
  }

  // ── Sidebar control ──────────────────────────────────────────────────────
  void _openSidebar() {
    HapticFeedback.selectionClick();
    FocusManager.instance.primaryFocus?.unfocus();
    _sidebar.animateTo(1.0, curve: AppMotion.enter, duration: AppMotion.emphasized);
  }

  void _closeSidebar() {
    _sidebar.animateBack(0.0, curve: AppMotion.enter, duration: AppMotion.standard);
  }

  void _settleSidebar(double velocity) {
    final v = velocity / _sidebarWidth;
    if (v > 0.8 || (v > -0.8 && _sidebar.value > 0.5)) {
      _sidebar.animateTo(1.0, curve: AppMotion.enter, duration: AppMotion.standard);
    } else {
      _closeSidebar();
    }
  }

  void _dragSidebar(double dx) {
    _sidebar.value = (_sidebar.value + dx / _sidebarWidth).clamp(0.0, 1.0);
  }

  // ── Navigation ───────────────────────────────────────────────────────────
  int get _branchCount => widget.navigationShell.route.branches.length;

  void _goTo(AppDestination dest) {
    final index = dest.branchIndex;
    if (index != null && index < _branchCount) {
      widget.navigationShell.goBranch(
        index,
        // Re-tapping the active tab pops it back to its root (iOS behaviour).
        initialLocation: index == widget.navigationShell.currentIndex,
      );
    } else if (index == null) {
      context.push(dest.path);
    } else {
      context.go(dest.path);
    }
  }

  void _onSidebarSelect(AppDestination dest) {
    _closeSidebar();
    _goTo(dest);
  }

  void _onDockChanged(
    int index,
    List<AppDestination> pinned,
    int moreIndex,
  ) {
    if (index == moreIndex) {
      if (_sidebar.value > 0.5) {
        _closeSidebar();
      } else {
        _openSidebar();
      }
    } else if (index >= 0 && index < pinned.length) {
      if (_sidebar.value > 0) {
        _closeSidebar();
      }
      _goTo(pinned[index]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = widget.navigationShell.currentIndex;
    if (currentIndex != _lastIndex) {
      _lastIndex = currentIndex;
      _activationTick++;
    }

    final prefs = ref.watch(navPrefsProvider);
    final pinned = prefs.pinnedDestinations
        .where((d) => d.branchIndex! < _branchCount)
        .toList(growable: false);
    final unread = ref.watch(totalUnreadChatCountProvider).value ?? 0;
    final navBottom = getFloatingNavBarBottom(context);
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 80;
    final screenWidth = MediaQuery.sizeOf(context).width;
    _sidebarWidth = math.min(320.0, screenWidth * 0.84);

    String path = '';
    try {
      path = GoRouterState.of(context).uri.path;
    } catch (_) {}
    final isNestedRoute = path.split('/').where((s) => s.isNotEmpty).length > 1;

    return AppShellScope(
      openSidebar: _openSidebar,
      closeSidebar: _closeSidebar,
      child: ValueListenableBuilder<bool>(
        valueListenable: _sidebarOpen,
        builder: (context, open, child) => PopScope(
          canPop: !open,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && open) _closeSidebar();
          },
          child: child!,
        ),
        child: Scaffold(
          backgroundColor: OledTheme.bg,
          extendBody: true,
          resizeToAvoidBottomInset: false,
          body: Stack(
            children: [
              // ── Content (gently pushed right while the sidebar opens) ──
              AnimatedBuilder(
                animation: _sidebar,
                builder: (context, child) => Transform.translate(
                  offset: Offset(_sidebar.value * 28.0, 0),
                  child: child,
                ),
                child: RepaintBoundary(
                  child: TabActivationScope(
                    activeTabIndex: currentIndex,
                    activationTick: _activationTick,
                    child: widget.navigationShell,
                  ),
                ),
              ),

              // ── Floating glass dock navbar ────────────────────────────
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: RepaintBoundary(
                  child: AnimatedSlide(
                    offset: keyboardOpen ? const Offset(0, 1.8) : Offset.zero,
                    duration: AppMotion.standard,
                    curve: AppMotion.enter,
                    child: IgnorePointer(
                      ignoring: keyboardOpen,
                      child: FadeTransition(
                        opacity: _navEntranceFade,
                        child: SlideTransition(
                          position: _navEntrance,
                          child: ValueListenableBuilder<bool>(
                            valueListenable: _sidebarOpen,
                            builder: (context, open, _) {
                              final dockItems = pinned.length == 4 &&
                                      pinned[0].id == 'today' &&
                                      pinned[1].id == 'skills' &&
                                      pinned[2].id == 'calendar' &&
                                      pinned[3].id == 'progress'
                                  ? [
                                      const DockItem(
                                        icon: Icons.today_rounded,
                                        label: 'Today',
                                      ),
                                      const DockItem(
                                        icon: Icons.psychology_rounded,
                                        label: 'Skills',
                                      ),
                                      const DockItem(
                                        icon: Icons.calendar_month_rounded,
                                        label: 'Calendar',
                                      ),
                                      const DockItem(
                                        icon: Icons.insights_rounded,
                                        label: 'Progress',
                                      ),
                                      DockItem(
                                        icon: Icons.grid_view_rounded,
                                        label: 'More',
                                        badge: unread > 0,
                                        actionOnly: true,
                                      ),
                                    ]
                                  : [
                                      for (final d in pinned)
                                        DockItem(
                                          icon: d.icon,
                                          label: d.label,
                                        ),
                                      DockItem(
                                        icon: Icons.grid_view_rounded,
                                        label: 'More',
                                        badge: unread > 0,
                                        actionOnly: true,
                                      ),
                                    ];

                              final moreIndex = dockItems.length - 1;
                              final pinnedIndex = pinned.indexWhere(
                                (d) => d.branchIndex == currentIndex,
                              );
                              final dockCurrentIndex =
                                  (open || pinnedIndex < 0)
                                      ? moreIndex
                                      : pinnedIndex;

                              return FloatingDock(
                                items: dockItems,
                                currentIndex: dockCurrentIndex,
                                accentColor: OledTheme.accent,
                                onChanged: (idx) => _onDockChanged(
                                  idx,
                                  pinned,
                                  moreIndex,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Left edge swipe to open sidebar ───────────────────────
              if (!isNestedRoute)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: navBottom + _kNavBarHeight + 8,
                  width: 16,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onHorizontalDragUpdate: (d) => _dragSidebar(d.delta.dx),
                    onHorizontalDragEnd: (d) =>
                        _settleSidebar(d.velocity.pixelsPerSecond.dx),
                  ),
                ),

              // ── Sidebar ───────────────────────────────────────────────
              _SidebarOverlay(
                controller: _sidebar,
                isOpen: _sidebarOpen,
                width: _sidebarWidth,
                onClose: _closeSidebar,
                onDrag: _dragSidebar,
                onDragEnd: _settleSidebar,
                child: _SidebarPanel(
                  controller: _sidebar,
                  currentIndex: currentIndex,
                  branchCount: _branchCount,
                  unreadCount: unread,
                  onSelect: _onSidebarSelect,
                  onClose: _closeSidebar,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  Glass surface — real blur on capable devices, solid graphite on slow ones
// ═════════════════════════════════════════════════════════════════════════════

class _GlassSurface extends ConsumerWidget {
  final BorderRadius borderRadius;
  final Widget child;
  final double blur;

  const _GlassSurface({
    required this.borderRadius,
    required this.child,
    this.blur = 24,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(navPrefsProvider.select((p) => p.glassMode));
    return ValueListenableBuilder<bool>(
      valueListenable: DevicePerformance.isLowEnd,
      builder: (context, lowEnd, _) {
        final useBlur =
            mode == GlassMode.full || (mode == GlassMode.auto && !lowEnd);

        Widget body = DecoratedBox(
          decoration: BoxDecoration(
            color: useBlur ? OledTheme.glassFill : OledTheme.glassFillOpaque,
            borderRadius: borderRadius,
            border: Border.all(color: OledTheme.glassBorder, width: 0.6),
          ),
          child: child,
        );

        if (useBlur) {
          body = BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: body,
          );
        }

        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            boxShadow: const [
              BoxShadow(
                color: Color(0x80000000),
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(borderRadius: borderRadius, child: body),
        );
      },
    );
  }
}


// ═════════════════════════════════════════════════════════════════════════════
//  Sidebar
// ═════════════════════════════════════════════════════════════════════════════

class _SidebarOverlay extends StatelessWidget {
  final AnimationController controller;
  final ValueNotifier<bool> isOpen;
  final double width;
  final VoidCallback onClose;
  final ValueChanged<double> onDrag;
  final ValueChanged<double> onDragEnd;
  final Widget child;

  const _SidebarOverlay({
    required this.controller,
    required this.isOpen,
    required this.width,
    required this.onClose,
    required this.onDrag,
    required this.onDragEnd,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isOpen,
      child: child,
      builder: (context, open, panel) {
        // Fully removed from the tree when closed — zero cost.
        if (!open) return const SizedBox.shrink();
        return Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onClose,
            onHorizontalDragUpdate: (d) => onDrag(d.delta.dx),
            onHorizontalDragEnd: (d) => onDragEnd(d.velocity.pixelsPerSecond.dx),
            child: Stack(
              children: [
                // Dim scrim — animated color, no saveLayer.
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: controller,
                    builder: (context, _) => ColoredBox(
                      color: Color.fromRGBO(0, 0, 0, 0.6 * controller.value),
                    ),
                  ),
                ),
                AnimatedBuilder(
                  animation: controller,
                  builder: (context, child) => Transform.translate(
                    offset: Offset(-(1 - controller.value) * (width + 24), 0),
                    child: child,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        10,
                        MediaQuery.paddingOf(context).top + 8,
                        0,
                        math.max(MediaQuery.paddingOf(context).bottom, 10) + 8,
                      ),
                      child: SizedBox(
                        width: width,
                        child: GestureDetector(
                          onTap: () {}, // swallow taps inside the panel
                          child: RepaintBoundary(child: panel),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SidebarPanel extends ConsumerStatefulWidget {
  final AnimationController controller;
  final int currentIndex;
  final int branchCount;
  final int unreadCount;
  final ValueChanged<AppDestination> onSelect;
  final VoidCallback onClose;

  const _SidebarPanel({
    required this.controller,
    required this.currentIndex,
    required this.branchCount,
    required this.unreadCount,
    required this.onSelect,
    required this.onClose,
  });

  @override
  ConsumerState<_SidebarPanel> createState() => _SidebarPanelState();
}

class _SidebarPanelState extends ConsumerState<_SidebarPanel> {
  static const _staggerSlots = 12;
  late final List<Animation<double>> _stagger;
  bool _editing = false;
  bool _limitHint = false;
  Timer? _limitTimer;

  @override
  void dispose() {
    _limitTimer?.cancel();
    for (final a in _stagger) {
      (a as CurvedAnimation).dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _stagger = List.generate(_staggerSlots, (i) {
      final start = (0.10 + i * 0.045).clamp(0.0, 0.7);
      return CurvedAnimation(
        parent: widget.controller,
        curve: Interval(start, (start + 0.45).clamp(0.0, 1.0), curve: AppMotion.enter),
        reverseCurve: const Interval(0.0, 1.0),
      );
    });
  }

  Widget _staggered(int slot, Widget child) {
    final anim = _stagger[slot.clamp(0, _staggerSlots - 1)];
    return FadeTransition(
      opacity: anim,
      child: AnimatedBuilder(
        animation: anim,
        builder: (context, child) => Transform.translate(
          offset: Offset(-14 * (1 - anim.value), 0),
          child: child,
        ),
        child: child,
      ),
    );
  }

  void _flashLimit() {
    HapticFeedback.mediumImpact();
    setState(() => _limitHint = true);
    _limitTimer?.cancel();
    _limitTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _limitHint = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(navPrefsProvider);
    final notifier = ref.read(navPrefsProvider.notifier);
    final destinations = AppDestinations.all
        .where((d) => d.branchIndex == null || d.branchIndex! < widget.branchCount)
        .toList();

    var slot = 0;
    return _GlassSurface(
      borderRadius: BorderRadius.circular(28),
      blur: 30,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _staggered(slot++, _SidebarHeader(onClose: widget.onClose)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18),
            child: Divider(height: 1, color: OledTheme.glassBorder),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
              physics: const BouncingScrollPhysics(),
              children: [
                _staggered(slot++, const _SectionLabel('Navigate')),
                for (final d in destinations)
                  _staggered(
                    slot++,
                    _SidebarRow(
                      destination: d,
                      active: d.branchIndex != null && d.branchIndex == widget.currentIndex,
                      pinned: prefs.pinned.contains(d.id),
                      badge: d.id == 'messages' ? widget.unreadCount : 0,
                      onTap: () => widget.onSelect(d),
                    ),
                  ),
                const SizedBox(height: 14),
                _staggered(
                  slot++,
                  _SectionLabel(
                    'Bottom bar',
                    trailing: _TextAction(
                      label: _editing ? 'Done' : 'Edit',
                      onTap: () => setState(() => _editing = !_editing),
                    ),
                  ),
                ),
                _staggered(
                  slot++,
                  AnimatedSize(
                    duration: AppMotion.standard,
                    curve: AppMotion.enter,
                    alignment: Alignment.topCenter,
                    child: _editing
                        ? _TabEditor(
                            prefs: prefs,
                            branchCount: widget.branchCount,
                            limitHint: _limitHint,
                            onToggle: (id) {
                              if (!notifier.togglePin(id)) _flashLimit();
                            },
                            onReorder: notifier.reorder,
                            onReset: notifier.resetPinned,
                          )
                        : _PinnedPreview(prefs: prefs),
                  ),
                ),
                const SizedBox(height: 14),
                _staggered(slot++, const _SectionLabel('Performance')),
                _staggered(
                  slot++,
                  _GlassModePicker(
                    mode: prefs.glassMode,
                    onChanged: notifier.setGlassMode,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarHeader extends ConsumerWidget {
  final VoidCallback onClose;
  const _SidebarHeader({required this.onClose});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).valueOrNull;
    final user = ref.watch(currentUserProvider);
    final name = (profile?.fullName.trim().isNotEmpty ?? false)
        ? profile!.fullName.trim()
        : 'FocusFlow';
    final email = profile?.email.isNotEmpty == true ? profile!.email : (user?.email ?? '');
    final initials = name
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 12, 16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: OledTheme.accent.withValues(alpha: 0.16),
              shape: BoxShape.circle,
              border: Border.all(color: OledTheme.accent.withValues(alpha: 0.35)),
            ),
            alignment: Alignment.center,
            child: Text(
              initials.isEmpty ? 'F' : initials,
              style: const TextStyle(
                color: OledTheme.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: OledTheme.textPrimary,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: OledTheme.textSecondary, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          _CircleButton(icon: LucideIcons.x, onTap: onClose, label: 'Close sidebar'),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const _SectionLabel(this.text, {this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 6, 8),
      child: Row(
        children: [
          Text(
            text.toUpperCase(),
            style: const TextStyle(
              color: OledTheme.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.9,
            ),
          ),
          const Spacer(),
          ?trailing,
        ],
      ),
    );
  }
}

class _TextAction extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _TextAction({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: AnimatedSwitcher(
          duration: AppMotion.fast,
          child: Text(
            label,
            key: ValueKey(label),
            style: const TextStyle(
              color: OledTheme.accent,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String label;
  const _CircleButton({required this.icon, required this.onTap, required this.label});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: Color(0x14FFFFFF),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 15, color: OledTheme.textSecondary),
        ),
      ),
    );
  }
}

class _SidebarRow extends StatefulWidget {
  final AppDestination destination;
  final bool active;
  final bool pinned;
  final int badge;
  final VoidCallback onTap;

  const _SidebarRow({
    required this.destination,
    required this.active,
    required this.pinned,
    required this.badge,
    required this.onTap,
  });

  @override
  State<_SidebarRow> createState() => _SidebarRowState();
}

class _SidebarRowState extends State<_SidebarRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.destination;
    final active = widget.active;
    final bg = active
        ? const Color(0x17FFFFFF)
        : (_pressed ? const Color(0x0DFFFFFF) : Colors.transparent);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: AppMotion.instant,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.standardCurve,
          margin: const EdgeInsets.only(bottom: 2),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: active
                      ? OledTheme.accent.withValues(alpha: 0.18)
                      : const Color(0x0FFFFFFF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  d.icon,
                  size: 16,
                  color: active ? OledTheme.accent : OledTheme.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.label,
                      style: TextStyle(
                        color: active ? OledTheme.textPrimary : const Color(0xFFE4E4E7),
                        fontSize: 14,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      d.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: OledTheme.textMuted, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              if (widget.badge > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: OledTheme.coral,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    widget.badge > 99 ? '99+' : '${widget.badge}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else if (widget.pinned)
                const Icon(LucideIcons.pin, size: 13, color: OledTheme.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact read-only preview of the current bottom bar.
class _PinnedPreview extends StatelessWidget {
  final NavPrefs prefs;
  const _PinnedPreview({required this.prefs});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0x0AFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: OledTheme.glassBorder, width: 0.6),
      ),
      child: Row(
        children: [
          for (final d in prefs.pinnedDestinations)
            Expanded(
              child: Column(
                children: [
                  Icon(d.icon, size: 16, color: OledTheme.textSecondary),
                  const SizedBox(height: 4),
                  Text(
                    d.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: OledTheme.textMuted, fontSize: 10),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TabEditor extends StatelessWidget {
  final NavPrefs prefs;
  final int branchCount;
  final bool limitHint;
  final ValueChanged<String> onToggle;
  final void Function(int, int) onReorder;
  final VoidCallback onReset;

  const _TabEditor({
    required this.prefs,
    required this.branchCount,
    required this.limitHint,
    required this.onToggle,
    required this.onReorder,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final pinned = prefs.pinnedDestinations;
    final available = AppDestinations.all
        .where((d) =>
            d.isPinnable && d.branchIndex! < branchCount && !prefs.pinned.contains(d.id))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
          child: AnimatedDefaultTextStyle(
            duration: AppMotion.fast,
            style: TextStyle(
              color: limitHint ? OledTheme.coral : OledTheme.textMuted,
              fontSize: 11.5,
              height: 1.35,
            ),
            child: const Text('Drag to reorder. Keep 2–4 tabs in the bar.'),
          ),
        ),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          itemCount: pinned.length,
          onReorder: onReorder,
          proxyDecorator: (child, index, animation) => AnimatedBuilder(
            animation: animation,
            builder: (context, child) => Transform.scale(
              scale: 1 + 0.03 * Curves.easeOut.transform(animation.value),
              child: child,
            ),
            child: Material(color: Colors.transparent, child: child),
          ),
          itemBuilder: (context, i) {
            final d = pinned[i];
            return _EditRow(
              key: ValueKey('pinned_${d.id}'),
              destination: d,
              pinned: true,
              index: i,
              onToggle: () => onToggle(d.id),
            );
          },
        ),
        if (available.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(10, 10, 10, 6),
            child: Text(
              'More tabs',
              style: TextStyle(
                color: OledTheme.textMuted,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          for (final d in available)
            _EditRow(
              key: ValueKey('avail_${d.id}'),
              destination: d,
              pinned: false,
              onToggle: () => onToggle(d.id),
            ),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 4, top: 4),
            child: _TextAction(label: 'Reset to default', onTap: onReset),
          ),
        ),
      ],
    );
  }
}

class _EditRow extends StatelessWidget {
  final AppDestination destination;
  final bool pinned;
  final int? index;
  final VoidCallback onToggle;

  const _EditRow({
    super.key,
    required this.destination,
    required this.pinned,
    required this.onToggle,
    this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
      decoration: BoxDecoration(
        color: pinned ? const Color(0x0FFFFFFF) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HapticFeedback.selectionClick();
              onToggle();
            },
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                pinned ? LucideIcons.minusCircle : LucideIcons.plusCircle,
                size: 18,
                color: pinned ? OledTheme.coral : OledTheme.emerald,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Icon(destination.icon, size: 15, color: OledTheme.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              destination.label,
              style: const TextStyle(
                color: OledTheme.textPrimary,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (pinned && index != null)
            ReorderableDragStartListener(
              index: index!,
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(LucideIcons.gripVertical, size: 16, color: OledTheme.textMuted),
              ),
            ),
        ],
      ),
    );
  }
}

class _GlassModePicker extends StatelessWidget {
  final GlassMode mode;
  final ValueChanged<GlassMode> onChanged;
  const _GlassModePicker({required this.mode, required this.onChanged});

  static const _labels = {
    GlassMode.auto: 'Auto',
    GlassMode.full: 'Glass',
    GlassMode.lite: 'Lite',
  };

  @override
  Widget build(BuildContext context) {
    final modes = GlassMode.values;
    final selected = modes.indexOf(mode);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 36,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0x0FFFFFFF),
              borderRadius: BorderRadius.circular(11),
            ),
            child: LayoutBuilder(
              builder: (context, c) {
                final w = c.maxWidth / modes.length;
                return Stack(
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(end: selected.toDouble()),
                      duration: AppMotion.standard,
                      curve: AppMotion.enter,
                      builder: (context, v, child) =>
                          Transform.translate(offset: Offset(v * w, 0), child: child),
                      child: Container(
                        width: w,
                        height: c.maxHeight,
                        decoration: BoxDecoration(
                          color: OledTheme.subtleSurface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: OledTheme.glassBorder, width: 0.6),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        for (final m in modes)
                          Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                onChanged(m);
                              },
                              child: Center(
                                child: Text(
                                  _labels[m]!,
                                  style: TextStyle(
                                    color: m == mode
                                        ? OledTheme.textPrimary
                                        : OledTheme.textMuted,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(6, 8, 6, 0),
            child: Text(
              'Lite swaps live blur for solid surfaces on slower phones. '
              'Animations stay the same.',
              style: TextStyle(color: OledTheme.textMuted, fontSize: 11.5, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
