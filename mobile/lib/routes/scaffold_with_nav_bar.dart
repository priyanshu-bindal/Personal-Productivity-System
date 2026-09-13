import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../core/theme/app_colors.dart';
import '../providers/chat_provider.dart';

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
    with SingleTickerProviderStateMixin {
  late final AnimationController _menuController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<Offset> _slideAnimation;

  // Staggered animations for individual items
  late final List<Animation<double>> _itemFades;
  late final List<Animation<Offset>> _itemSlides;

  bool _isMenuOpen = false;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _menuController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      reverseDuration: const Duration(milliseconds: 190),
    );

    final curved = CurvedAnimation(
      parent: _menuController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(curved);
    _scaleAnimation = Tween<double>(begin: 0.94, end: 1.0).animate(curved);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(curved);

    // Staggered item entrance intervals
    _itemFades = [
      Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _menuController,
          curve: const Interval(0.00, 0.65, curve: Curves.easeOutCubic),
        ),
      ),
      Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _menuController,
          curve: const Interval(0.12, 0.77, curve: Curves.easeOutCubic),
        ),
      ),
      Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _menuController,
          curve: const Interval(0.24, 0.89, curve: Curves.easeOutCubic),
        ),
      ),
      Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _menuController,
          curve: const Interval(0.36, 1.00, curve: Curves.easeOutCubic),
        ),
      ),
    ];

    _itemSlides = [
      Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _menuController,
          curve: const Interval(0.00, 0.65, curve: Curves.easeOutCubic),
        ),
      ),
      Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _menuController,
          curve: const Interval(0.12, 0.77, curve: Curves.easeOutCubic),
        ),
      ),
      Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _menuController,
          curve: const Interval(0.24, 0.89, curve: Curves.easeOutCubic),
        ),
      ),
      Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _menuController,
          curve: const Interval(0.36, 1.00, curve: Curves.easeOutCubic),
        ),
      ),
    ];
  }

  @override
  void dispose() {
    _menuController.dispose();
    super.dispose();
  }

  void _openMoreMenu() {
    if (_isMenuOpen) return;
    setState(() => _isMenuOpen = true);
    _menuController.forward(from: 0.0);
  }

  Future<void> _closeMoreMenu() async {
    if (!_isMenuOpen) return;
    await _menuController.reverse();
    if (mounted) {
      setState(() => _isMenuOpen = false);
    }
  }

  void _onTap(int index) {
    if (index == 4) {
      if (_menuController.isAnimating) return;
      if (_isMenuOpen) {
        _closeMoreMenu();
      } else {
        _openMoreMenu();
      }
    } else {
      if (_isMenuOpen) {
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
    final totalUnread = ref.watch(totalUnreadChatCountProvider).value ?? 0;

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
        subtitle: 'Practice defaults & account preferences',
        isActive: currentPath.startsWith('/settings'),
      ),
    ];

    return PopScope(
      canPop: !_isMenuOpen,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isMenuOpen) {
          _closeMoreMenu();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        extendBody: true,
        body: Stack(
          children: [
            // Main navigation content
            widget.navigationShell,

            // Backdrop Barrier when More menu is open
            if (_isMenuOpen)
              Positioned.fill(
                child: GestureDetector(
                  onTap: _closeMoreMenu,
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedBuilder(
                    animation: _fadeAnimation,
                    builder: (context, child) => Container(
                      color: Colors.black.withValues(
                        alpha: 0.45 * _fadeAnimation.value,
                      ),
                    ),
                  ),
                ),
              ),

            // Docked Floating More Menu
            if (_isMenuOpen)
              Positioned(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).padding.bottom + 86,
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 340),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        alignment: const Alignment(0.85, 1.0),
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                              child: Container(
                                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                                decoration: BoxDecoration(
                                  color: const Color(0xF20E1526),
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                    color: AppColors.border.withValues(alpha: 0.75),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.5),
                                      blurRadius: 28,
                                      offset: const Offset(0, 10),
                                    ),
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.08),
                                      blurRadius: 16,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // Header
                                    Row(
                                      children: [
                                        const Text(
                                          'MORE FEATURES',
                                          style: TextStyle(
                                            color: AppColors.textMuted,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 1.1,
                                          ),
                                        ),
                                        const Spacer(),
                                        GestureDetector(
                                          onTap: _closeMoreMenu,
                                          behavior: HitTestBehavior.opaque,
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(alpha: 0.06),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              LucideIcons.x,
                                              size: 14,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),

                                    // Staggered animated items
                                    ...List.generate(menuItems.length, (index) {
                                      final item = menuItems[index];
                                      return Padding(
                                        padding: EdgeInsets.only(
                                          bottom: index < menuItems.length - 1 ? 8 : 0,
                                        ),
                                        child: FadeTransition(
                                          opacity: _itemFades[index],
                                          child: SlideTransition(
                                            position: _itemSlides[index],
                                            child: _FloatingMoreMenuItem(
                                              icon: item.icon,
                                              color: item.color,
                                              title: item.title,
                                              subtitle: item.subtitle,
                                              badgeCount: item.badgeCount,
                                              isActive: item.isActive,
                                              onTap: () => _navigateFromMore(item.route),
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            height: 68,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x3D000000),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xF00E1526),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: AppColors.border,
                      width: 1,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final itemWidth = constraints.maxWidth / 5;
                      final effectiveIndex = _isMenuOpen ? 4 : currentIndex;
                      final alignmentX = -1.0 + (effectiveIndex * 0.5);

                      return Stack(
                        children: [
                          // Ultra-smooth Compact Active Pill Indicator
                          AnimatedAlign(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                            alignment: Alignment(alignmentX, 0.0),
                            child: SizedBox(
                              width: itemWidth,
                              height: double.infinity,
                              child: Container(
                                margin: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryBg,
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                    color: AppColors.primary.withValues(alpha: 0.35),
                                    width: 1,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Tab Items
                          Row(
                            children: [
                              _NavBarItem(
                                icon: LucideIcons.layoutDashboard,
                                label: 'Today',
                                isSelected: currentIndex == 0 && !_isMenuOpen,
                                onTap: () => _onTap(0),
                              ),
                              _NavBarItem(
                                icon: LucideIcons.bookOpen,
                                label: 'Skills',
                                isSelected: currentIndex == 1 && !_isMenuOpen,
                                onTap: () => _onTap(1),
                              ),
                              _NavBarItem(
                                icon: LucideIcons.calendar,
                                label: 'Calendar',
                                isSelected: currentIndex == 2 && !_isMenuOpen,
                                onTap: () => _onTap(2),
                              ),
                              _NavBarItem(
                                icon: LucideIcons.trendingUp,
                                label: 'Progress',
                                isSelected: currentIndex == 3 && !_isMenuOpen,
                                onTap: () => _onTap(3),
                              ),
                              _NavBarItem(
                                icon: LucideIcons.moreHorizontal,
                                label: 'More',
                                isSelected: _isMenuOpen,
                                isOpen: _isMenuOpen,
                                hasBadge: totalUnread > 0,
                                onTap: () => _onTap(4),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isOpen;
  final bool hasBadge;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    this.isOpen = false,
    this.hasBadge = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = AppColors.primary;
    final inactiveColor = AppColors.textSecondary;
    final highlighted = isSelected || isOpen;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedScale(
                  duration: const Duration(milliseconds: 250),
                  scale: highlighted ? 1.08 : 1.0,
                  child: AnimatedRotation(
                    duration: const Duration(milliseconds: 250),
                    turns: isOpen ? 0.25 : 0.0,
                    curve: Curves.easeOutCubic,
                    child: Icon(
                      icon,
                      size: 19,
                      color: highlighted ? activeColor : inactiveColor,
                    ),
                  ),
                ),
                if (hasBadge)
                  Positioned(
                    top: -1,
                    right: -2,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF3B82F6),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x663B82F6),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: highlighted ? FontWeight.w600 : FontWeight.w400,
                color: highlighted ? activeColor : inactiveColor,
                letterSpacing: 0.1,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

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
            ? widget.color.withValues(alpha: 0.16)
            : widget.color.withValues(alpha: 0.09))
        : (_isPressed
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.03));

    final borderColor = widget.isActive
        ? widget.color.withValues(alpha: 0.45)
        : (_isPressed
            ? widget.color.withValues(alpha: 0.35)
            : Colors.white.withValues(alpha: 0.05));

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: borderColor,
            width: widget.isActive ? 1.2 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                widget.icon,
                color: widget.color,
                size: 20,
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
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
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
                                color: widget.color.withValues(alpha: 0.6),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 1),
                  Text(
                    widget.subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (widget.badgeCount > 0) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0x333B82F6),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0x663B82F6)),
                ),
                child: Text(
                  widget.badgeCount > 99 ? '99+' : widget.badgeCount.toString(),
                  style: const TextStyle(
                    color: Color(0xFF93C5FD),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],
            Icon(
              LucideIcons.chevronRight,
              color: widget.isActive ? widget.color : AppColors.textMuted,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
