import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../core/animation/tab_activation_scope.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/oled_theme.dart';
import '../providers/chat_provider.dart';
import 'app_router.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Per-destination accent colors for the glass navbar
// ─────────────────────────────────────────────────────────────────────────────
const _kNavAccents = <Color>[
  OledTheme.electricBlue, // Today
  OledTheme.cyan,         // Skills
  OledTheme.violet,       // Calendar
  OledTheme.amber,        // Progress
  OledTheme.electricBlue, // More
];

/// Height of the floating glass capsule (without bottom safe-area inset).
const double _kNavBarHeight = 68.0;

/// Bottom margin between the capsule and the safe-area bottom edge.
const double _kNavBarBottomMargin = 14.0;

/// Horizontal margin as a fraction of screen width (clamped).
const double _kNavBarHorizontalPaddingFraction = 0.04;

/// Calculates the bottom positioning for the floating navbar,
/// guaranteeing the 14 px gap is measured strictly above the device's bottom safe
/// area / system navigation controls (gesture pill or 3-button bar).
double getFloatingNavBarBottom(BuildContext context) {
  final mediaQuery = MediaQuery.of(context);
  final systemBottomInset =
      math.max(mediaQuery.padding.bottom, mediaQuery.viewPadding.bottom);
  // Ensure at least a minimal 10 px clearance even on devices reporting 0 safe area
  final effectiveBottomSafe = math.max(systemBottomInset, 10.0);
  return effectiveBottomSafe + _kNavBarBottomMargin;
}

/// Total clearance needed above the bottom of the screen so scrolling content
/// is never obscured behind the floating glass capsule.
double getNavBarClearance(BuildContext context) {
  final bottomPos = getFloatingNavBarBottom(context);
  return bottomPos + _kNavBarHeight + 12.0;
}

class ScaffoldWithNavBar extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNavBar({
    super.key,
    required this.navigationShell,
  });

  @override
  ConsumerState<ScaffoldWithNavBar> createState() => _ScaffoldWithNavBarState();
}

class _ScaffoldWithNavBarState extends ConsumerState<ScaffoldWithNavBar>
    with TickerProviderStateMixin, RouteAware {
  // ── Tab activation tick counter for card animation replay ─────────────
  int _activationTick = 0;
  int _lastIndex = -1;

  // ── More-menu animations ────────────────────────────────────────────────
  late final AnimationController _menuController;
  late final Animation<double> _curvedAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  // ── Entrance animations (run once on auth) ──────────────────────────────
  late final AnimationController _entranceController;
  late final Animation<double> _contentFade;
  late final Animation<Offset> _contentSlide;
  late final Animation<double> _contentScale;
  late final Animation<double> _navBarFade;
  late final Animation<Offset> _navBarSlide;

  final ValueNotifier<bool> _isMenuOpenNotifier = ValueNotifier<bool>(false);
  bool _isNavigating = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final modalRoute = ModalRoute.of(context);
    if (modalRoute != null) {
      appRouteObserver.subscribe(this, modalRoute);
    }
  }

  @override
  void didPopNext() {
    super.didPopNext();
    // Returning from a pushed route (e.g. /skills/:id, /notes, /money, /settings)
    // Increment activation tick so cards on the active tab replay their entrance animation!
    setState(() {
      _activationTick++;
    });
  }

  @override
  void initState() {
    super.initState();

    // ── More-menu controller (230 ms open / 200 ms close) ─────────────────
    _menuController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 230),
      reverseDuration: const Duration(milliseconds: 200),
    );

    _curvedAnimation = CurvedAnimation(
      parent: _menuController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    _fadeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_curvedAnimation);
    _scaleAnimation =
        Tween<double>(begin: 0.95, end: 1.0).animate(_curvedAnimation);

    // ── 480 ms coordinated entrance ─────────────────────────────────────
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );

    _contentFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.85, curve: Curves.easeOutCubic),
      ),
    );
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 14.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.85, curve: Curves.easeOutCubic),
      ),
    );
    _contentScale = Tween<double>(begin: 0.985, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    _navBarFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.15, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    _navBarSlide = Tween<Offset>(
      begin: const Offset(0, 24.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.15, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _entranceController.forward();
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    _isMenuOpenNotifier.dispose();
    _entranceController.dispose();
    _menuController.dispose();
    super.dispose();
  }

  // ── More-menu helpers ─────────────────────────────────────────────────
  void _openMoreMenu() {
    if (_isMenuOpenNotifier.value) return;
    _isMenuOpenNotifier.value = true;
    _menuController.forward(from: 0.0);
  }

  Future<void> _closeMoreMenu() async {
    if (!_isMenuOpenNotifier.value && _menuController.isDismissed) return;
    await _menuController.reverse();
    if (mounted) {
      _isMenuOpenNotifier.value = false;
    }
  }

  void _onTap(int index) {
    if (index == 4) {
      if (_menuController.isAnimating) return;
      if (_isMenuOpenNotifier.value) {
        _closeMoreMenu();
      } else {
        _openMoreMenu();
      }
    } else {
      if (_isMenuOpenNotifier.value) {
        _closeMoreMenu();
      }
      widget.navigationShell.goBranch(
        index,
        initialLocation: false,
      );
    }
  }

  void _navigateFromMore(String route) async {
    if (_isNavigating) return;
    _isNavigating = true;
    await _closeMoreMenu();
    if (mounted) {
      _isNavigating = false;
      context.push(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = widget.navigationShell.currentIndex;
    if (currentIndex != _lastIndex) {
      _lastIndex = currentIndex;
      _activationTick++;
    }
    final totalUnread = ref.watch(totalUnreadChatCountProvider).value ?? 0;
    final navBarBottom = getFloatingNavBarBottom(context);
    final isKeyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 80;

    String currentPath = '';
    try {
      currentPath = GoRouterState.of(context).uri.path;
    } catch (_) {}

    final menuItems = [
      _MoreItemData(
        route: '/messages',
        icon: LucideIcons.messageSquare,
        color: const Color(0xFF3B82F6),
        title: 'Messages',
        subtitle: '1-to-1 private chat & discussions',
        badgeCount: totalUnread,
        isActive: currentPath.startsWith('/messages'),
      ),
      _MoreItemData(
        route: '/notes',
        icon: LucideIcons.fileText,
        color: AppColors.accentCyan,
        title: 'Notes',
        subtitle: 'Personal learning notes & tags',
        isActive: currentPath.startsWith('/notes'),
      ),
      _MoreItemData(
        route: '/money',
        icon: LucideIcons.wallet,
        color: AppColors.primary,
        title: 'Money Tracker',
        subtitle: 'Personal expenses & monthly budgets',
        isActive: currentPath.startsWith('/money'),
      ),
      _MoreItemData(
        route: '/settings',
        icon: LucideIcons.settings,
        color: AppColors.secondary,
        title: 'Settings',
        subtitle: 'App preferences & account',
        isActive: currentPath.startsWith('/settings'),
      ),
    ];

    return ValueListenableBuilder<bool>(
      valueListenable: _isMenuOpenNotifier,
      builder: (context, isMenuOpen, child) {
        return PopScope(
          canPop: !isMenuOpen,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop && _isMenuOpenNotifier.value) {
              _closeMoreMenu();
            }
          },
          child: child!,
        );
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF030508),
        extendBody: true,
        body: Stack(
          children: [
            // ── Main content ─────────────────────────────────────────────
            RepaintBoundary(
              child: AnimatedBuilder(
                animation: _entranceController,
                builder: (context, child) => Transform.translate(
                  offset: _contentSlide.value,
                  child: Transform.scale(
                    scale: _contentScale.value,
                    child: Opacity(
                      opacity: _contentFade.value.clamp(0.0, 1.0),
                      child: child,
                    ),
                  ),
                ),
                child: TabActivationScope(
                  activeTabIndex: currentIndex,
                  activationTick: _activationTick,
                  child: widget.navigationShell,
                ),
              ),
            ),

            // ── More-menu overlay ────────────────────────────────────────
            _DockedMoreMenuOverlay(
              menuController: _menuController,
              isOpenNotifier: _isMenuOpenNotifier,
              fadeAnimation: _fadeAnimation,
              scaleAnimation: _scaleAnimation,
              curvedAnimation: _curvedAnimation,
              onClose: _closeMoreMenu,
              onNavigate: _navigateFromMore,
              menuItems: menuItems,
            ),

            // ── Floating Glass Navbar (Smooth keyboard hide/restore) ──────
            Positioned(
              left: 0,
              right: 0,
              bottom: navBarBottom,
              child: RepaintBoundary(
                child: AnimatedSlide(
                  offset: isKeyboardOpen ? const Offset(0, 1.8) : Offset.zero,
                  duration: const Duration(milliseconds: 240),
                  curve: isKeyboardOpen ? Curves.easeInCubic : Curves.easeOutCubic,
                  child: AnimatedOpacity(
                    opacity: isKeyboardOpen ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    child: IgnorePointer(
                      ignoring: isKeyboardOpen,
                      child: AnimatedBuilder(
                        animation: _entranceController,
                        builder: (context, child) => Transform.translate(
                          offset: _navBarSlide.value,
                          child: Opacity(
                            opacity: _navBarFade.value.clamp(0.0, 1.0),
                            child: child,
                          ),
                        ),
                        child: _FloatingGlassNavBar(
                          currentIndex: currentIndex,
                          isMenuOpenNotifier: _isMenuOpenNotifier,
                          onTap: _onTap,
                          hasBadge: totalUnread > 0,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  _FloatingGlassNavBar — The main glass capsule widget
// ═══════════════════════════════════════════════════════════════════════════════
class _FloatingGlassNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueNotifier<bool> isMenuOpenNotifier;
  final ValueChanged<int> onTap;
  final bool hasBadge;

  const _FloatingGlassNavBar({
    required this.currentIndex,
    required this.isMenuOpenNotifier,
    required this.onTap,
    this.hasBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding =
        (screenWidth * _kNavBarHorizontalPaddingFraction).clamp(12.0, 28.0);
    final navWidth = (screenWidth - horizontalPadding * 2).clamp(280.0, 520.0);

    // Adaptive blur: 12.0 sigma for excellent 60/120fps performance on mobile,
    // with automatic 0-blur high-opacity OLED fallback for accessibility/reduced motion
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final double blurSigma = reduceMotion ? 0.0 : 12.0;
    final glassColor = blurSigma > 0
        ? const Color(0xFF101722).withValues(alpha: 0.82)
        : const Color(0xF40D1420); // 96% opaque OLED surface fallback

    Widget glassBody = Container(
      decoration: BoxDecoration(
        color: glassColor,
        borderRadius: BorderRadius.circular(_kNavBarHeight / 2),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 0.8,
        ),
      ),
      child: Stack(
        children: [
          // ── Top edge highlight (glass refraction line) ────────
          Positioned(
            top: 0,
            left: _kNavBarHeight / 2,
            right: _kNavBarHeight / 2,
            height: 0.6,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.0),
                    Colors.white.withValues(alpha: 0.10),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          // ── Nav items with sliding capsule ───────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: ValueListenableBuilder<bool>(
              valueListenable: isMenuOpenNotifier,
              builder: (context, isMenuOpen, _) {
                return _GlassNavBarContent(
                  currentIndex: currentIndex,
                  isMenuOpen: isMenuOpen,
                  onTap: onTap,
                  hasBadge: hasBadge,
                );
              },
            ),
          ),
        ],
      ),
    );

    // Apply BackdropFilter only if blur is enabled
    if (blurSigma > 0) {
      glassBody = BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: glassBody,
      );
    }

    return Center(
      child: SizedBox(
        width: navWidth,
        height: _kNavBarHeight,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_kNavBarHeight / 2),
            // Soft floating shadow
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.55),
                blurRadius: 28,
                spreadRadius: -4,
                offset: const Offset(0, 10),
              ),
              // Ambient accent glow
              BoxShadow(
                color: OledTheme.electricBlue.withValues(alpha: 0.06),
                blurRadius: 32,
                spreadRadius: -2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_kNavBarHeight / 2),
            child: glassBody,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  _GlassNavBarContent — Layout with animated sliding capsule + items
// ═══════════════════════════════════════════════════════════════════════════════
class _GlassNavBarContent extends StatelessWidget {
  final int currentIndex;
  final bool isMenuOpen;
  final ValueChanged<int> onTap;
  final bool hasBadge;

  const _GlassNavBarContent({
    required this.currentIndex,
    required this.isMenuOpen,
    required this.onTap,
    required this.hasBadge,
  });

  static const _icons = <IconData>[
    LucideIcons.layoutGrid,
    LucideIcons.bookOpen,
    LucideIcons.calendar,
    LucideIcons.trendingUp,
    LucideIcons.moreHorizontal,
  ];

  static const _labels = <String>[
    'Today',
    'Skills',
    'Calendar',
    'Progress',
    'More',
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = constraints.maxWidth / 5;
        final itemHeight = constraints.maxHeight;
        final effectiveIndex = isMenuOpen ? 4 : currentIndex;
        final accent = _kNavAccents[effectiveIndex];

        return Stack(
          children: [
            // ── Snappy sliding active capsule (200ms easeOutCubic: no lag) ─
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              left: effectiveIndex * itemWidth + 3,
              top: 2,
              width: itemWidth - 6,
              height: itemHeight - 4,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(itemHeight / 2),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.30),
                    width: 0.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.15),
                      blurRadius: 10,
                      spreadRadius: -2,
                    ),
                  ],
                ),
              ),
            ),

            // ── Navigation items ──────────────────────────────────────
            Row(
              children: List.generate(5, (index) {
                final isSelected =
                    (index == 4) ? isMenuOpen : (currentIndex == index && !isMenuOpen);

                return SizedBox(
                  width: itemWidth,
                  height: itemHeight,
                  child: _GlassNavItem(
                    icon: _icons[index],
                    label: _labels[index],
                    accent: _kNavAccents[index],
                    isSelected: isSelected,
                    isMore: index == 4,
                    isMenuOpen: isMenuOpen,
                    hasBadge: index == 4 && hasBadge,
                    onTap: () => onTap(index),
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  _GlassNavItem — Individual destination with immediate tactile feedback
// ═══════════════════════════════════════════════════════════════════════════════
class _GlassNavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final bool isSelected;
  final bool isMore;
  final bool isMenuOpen;
  final bool hasBadge;
  final VoidCallback onTap;

  const _GlassNavItem({
    required this.icon,
    required this.label,
    required this.accent,
    required this.isSelected,
    this.isMore = false,
    this.isMenuOpen = false,
    this.hasBadge = false,
    required this.onTap,
  });

  @override
  State<_GlassNavItem> createState() => _GlassNavItemState();
}

class _GlassNavItemState extends State<_GlassNavItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    // Fast, crisp press animation: 70ms in, 100ms out — immediate, not bouncy
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 70),
      reverseDuration: const Duration(milliseconds: 100),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) {
    if (!_isPressed) {
      _isPressed = true;
      _pressController.forward();
      setState(() {});
    }
  }

  void _handleTapUp(TapUpDetails _) {
    _isPressed = false;
    _pressController.reverse();
    setState(() {});
  }

  void _handleTapCancel() {
    _isPressed = false;
    _pressController.reverse();
    setState(() {});
  }

  void _handleTap() {
    HapticFeedback.selectionClick();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final sel = widget.isSelected;
    final accent = widget.accent;
    const inactiveColor = Color(0xFF5A6678);
    final iconColor = sel ? accent : inactiveColor;
    final labelColor = sel ? accent : const Color(0xFF7A8899);

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _pressController,
        builder: (context, child) {
          // Snappy 0.94x press scale
          final pressScale = 1.0 - (_pressController.value * 0.06);
          return Transform.scale(scale: pressScale, child: child);
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Icon with snappy 1.12x scale transition ─────────────
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedScale(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  scale: sel ? 1.12 : 1.0,
                  child: widget.isMore
                      ? AnimatedRotation(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                          turns: widget.isMenuOpen ? 0.25 : 0.0,
                          child: Icon(
                            widget.icon,
                            size: 19,
                            color: iconColor,
                          ),
                        )
                      : Icon(
                          widget.icon,
                          size: 19,
                          color: iconColor,
                        ),
                ),

                // ── Unread badge on More ──────────────────────────────
                if (widget.hasBadge)
                  Positioned(
                    top: -2,
                    right: -3,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: OledTheme.coral,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: OledTheme.coral.withValues(alpha: 0.6),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 4),

            // ── Label with smooth style transition ───────────────────
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
              style: TextStyle(
                fontSize: sel ? 10.0 : 9.5,
                fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                color: labelColor,
                letterSpacing: sel ? 0.2 : 0.0,
                height: 1.1,
              ),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 160),
                opacity: sel ? 1.0 : 0.75,
                child: Text(widget.label, maxLines: 1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Data class for More-menu items
// ═══════════════════════════════════════════════════════════════════════════════
class _MoreItemData {
  final String route;
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final int badgeCount;
  final bool isActive;

  const _MoreItemData({
    required this.route,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.badgeCount = 0,
    this.isActive = false,
  });
}

// ═══════════════════════════════════════════════════════════════════════════════
//  _DockedMoreMenuOverlay — Floating overlay popup from the More button
// ═══════════════════════════════════════════════════════════════════════════════
class _DockedMoreMenuOverlay extends StatelessWidget {
  final AnimationController menuController;
  final ValueNotifier<bool> isOpenNotifier;
  final Animation<double> fadeAnimation;
  final Animation<double> scaleAnimation;
  final Animation<double> curvedAnimation;
  final VoidCallback onClose;
  final void Function(String route) onNavigate;
  final List<_MoreItemData> menuItems;

  const _DockedMoreMenuOverlay({
    required this.menuController,
    required this.isOpenNotifier,
    required this.fadeAnimation,
    required this.scaleAnimation,
    required this.curvedAnimation,
    required this.onClose,
    required this.onNavigate,
    required this.menuItems,
  });

  @override
  Widget build(BuildContext context) {
    final navBarBottom = getFloatingNavBarBottom(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final double blurSigma = reduceMotion ? 0.0 : 14.0;
    final glassColor = blurSigma > 0
        ? const Color(0xFF0C1322).withValues(alpha: 0.88)
        : const Color(0xF6090E18);

    return ValueListenableBuilder<bool>(
      valueListenable: isOpenNotifier,
      builder: (context, isOpen, _) {
        return AnimatedBuilder(
          animation: menuController,
          builder: (context, _) {
            final isVisible = isOpen || menuController.value > 0.0;
            if (!isVisible) {
              return const SizedBox.shrink();
            }

            Widget menuBody = Container(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              decoration: BoxDecoration(
                color: glassColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.09),
                  width: 0.9,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.65),
                    blurRadius: 32,
                    offset: const Offset(0, 12),
                  ),
                  BoxShadow(
                    color: OledTheme.electricBlue.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Mini OLED Header
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: OledTheme.cyan,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'MORE FEATURES',
                        style: TextStyle(
                          color: OledTheme.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: onClose,
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                              width: 0.8,
                            ),
                          ),
                          child: const Icon(
                            LucideIcons.x,
                            size: 13,
                            color: OledTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Staggered Menu items with internal scroll safety
                  ...List.generate(menuItems.length, (index) {
                    final item = menuItems[index];
                    final start = (0.06 + index * 0.10).clamp(0.0, 1.0);
                    final end = (start + 0.40).clamp(0.0, 1.0);
                    final itemAnim = CurvedAnimation(
                      parent: menuController,
                      curve: Interval(start, end, curve: Curves.easeOutCubic),
                    );

                    return AnimatedBuilder(
                      animation: itemAnim,
                      builder: (context, child) {
                        final itemDy = (1.0 - itemAnim.value) * 8.0;
                        return Transform.translate(
                          offset: Offset(0, itemDy),
                          child: Opacity(
                            opacity: itemAnim.value.clamp(0.0, 1.0),
                            child: child,
                          ),
                        );
                      },
                      child: Padding(
                        padding: EdgeInsets.only(
                          bottom: index < menuItems.length - 1 ? 8 : 0,
                        ),
                        child: _FloatingMoreMenuItem(
                          icon: item.icon,
                          color: item.color,
                          title: item.title,
                          subtitle: item.subtitle,
                          badgeCount: item.badgeCount,
                          isActive: item.isActive,
                          onTap: () => onNavigate(item.route),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );

            if (blurSigma > 0) {
              menuBody = ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
                  child: menuBody,
                ),
              );
            }

            return RepaintBoundary(
              child: Stack(
                children: [
                  // Full screen backdrop barrier
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: onClose,
                      behavior: HitTestBehavior.opaque,
                      child: FadeTransition(
                        opacity: fadeAnimation,
                        child: Container(
                          color: const Color(0x78000000),
                        ),
                      ),
                    ),
                  ),

                  // Docked Floating More Menu — precisely positioned above the floating capsule
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: navBarBottom + _kNavBarHeight + 12,
                    child: Align(
                      alignment: Alignment.bottomRight,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: 336,
                          maxHeight: MediaQuery.sizeOf(context).height * 0.65,
                        ),
                        child: FadeTransition(
                          opacity: fadeAnimation,
                          child: ScaleTransition(
                            scale: scaleAnimation,
                            alignment: const Alignment(0.85, 1.0),
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: menuBody,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  _FloatingMoreMenuItem — Individual item in the More popup
// ═══════════════════════════════════════════════════════════════════════════════
class _FloatingMoreMenuItem extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final int badgeCount;
  final bool isActive;
  final VoidCallback onTap;

  const _FloatingMoreMenuItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.badgeCount = 0,
    this.isActive = false,
    required this.onTap,
  });

  @override
  State<_FloatingMoreMenuItem> createState() => _FloatingMoreMenuItemState();
}

class _FloatingMoreMenuItemState extends State<_FloatingMoreMenuItem> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isActive
        ? (_isPressed
            ? widget.color.withValues(alpha: 0.18)
            : widget.color.withValues(alpha: 0.11))
        : (_isPressed
            ? const Color(0xFF1A2333).withValues(alpha: 0.65)
            : const Color(0xFF0F1728).withValues(alpha: 0.50));

    final borderColor = widget.isActive
        ? widget.color.withValues(alpha: 0.50)
        : (_isPressed
            ? widget.color.withValues(alpha: 0.35)
            : Colors.white.withValues(alpha: 0.07));

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOutCubic,
        scale: _isPressed ? 0.965 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: borderColor,
              width: widget.isActive ? 1.2 : 0.9,
            ),
            boxShadow: widget.isActive
                ? [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.16),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: widget.color.withValues(alpha: 0.22),
                    width: 0.8,
                  ),
                ),
                child: Center(
                  child: Icon(
                    widget.icon,
                    color: widget.color,
                    size: 19,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          widget.title,
                          style: TextStyle(
                            color: widget.isActive
                                ? widget.color
                                : OledTheme.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                            letterSpacing: -0.1,
                          ),
                        ),
                        if (widget.isActive) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: widget.color,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: widget.color.withValues(alpha: 0.7),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 1.5),
                    Text(
                      widget.subtitle,
                      style: const TextStyle(
                        color: OledTheme.textSecondary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (widget.badgeCount > 0) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: OledTheme.coral.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: OledTheme.coral.withValues(alpha: 0.45),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    widget.badgeCount > 99
                        ? '99+'
                        : widget.badgeCount.toString(),
                    style: const TextStyle(
                      color: OledTheme.coral,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Icon(
                LucideIcons.chevronRight,
                color: widget.isActive
                    ? widget.color
                    : OledTheme.textMuted.withValues(alpha: 0.6),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
