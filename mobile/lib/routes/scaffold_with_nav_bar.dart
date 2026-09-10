import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/custom_bottom_sheet.dart';
import '../providers/chat_provider.dart';

class ScaffoldWithNavBar extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNavBar({
    super.key,
    required this.navigationShell,
  });

  void _onTap(BuildContext context, int index) {
    if (index == 4) {
      // "More" tab clicked - open popup menu
      _showMoreMenu(context);
    } else {
      // Switch tab without resetting initial location state
      navigationShell.goBranch(
        index,
        initialLocation: false,
      );
    }
  }

  void _showMoreMenu(BuildContext context) {
    CustomBottomSheet.show(
      context: context,
      title: 'More Features',
      subtitle: 'Messages, notes, expenses & settings',
      child: Consumer(
        builder: (context, ref, _) {
          final unreadChatCount = ref.watch(totalUnreadChatCountProvider).value ?? 0;

          return Column(
            children: [
              _MoreMenuItem(
                icon: LucideIcons.messageSquare,
                color: const Color(0xFF3B82F6),
                title: 'Messages',
                subtitle: '1-to-1 private chat & discussions',
                badgeCount: unreadChatCount,
                onTap: () {
                  Navigator.pop(context);
                  context.push('/messages');
                },
              ),
              const SizedBox(height: 12),
              _MoreMenuItem(
                icon: LucideIcons.fileText,
                color: AppColors.accentCyan,
                title: 'Notes',
                subtitle: 'Personal learning notes & tags',
                onTap: () {
                  Navigator.pop(context);
                  context.push('/notes');
                },
              ),
              const SizedBox(height: 12),
              _MoreMenuItem(
                icon: LucideIcons.wallet,
                color: AppColors.primary,
                title: 'Money Tracker',
                subtitle: 'Personal expenses & monthly budgets',
                onTap: () {
                  Navigator.pop(context);
                  context.push('/money');
                },
              ),
              const SizedBox(height: 12),
              _MoreMenuItem(
                icon: LucideIcons.settings,
                color: AppColors.secondary,
                title: 'Settings',
                subtitle: 'Practice defaults & account preferences',
                onTap: () {
                  Navigator.pop(context);
                  context.push('/settings');
                },
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = navigationShell.currentIndex;
    final totalUnread = ref.watch(totalUnreadChatCountProvider).value ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: navigationShell,
      extendBody: true,
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
                    final alignmentX = -1.0 + (currentIndex * 0.5);

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
                              isSelected: currentIndex == 0,
                              onTap: () => _onTap(context, 0),
                            ),
                            _NavBarItem(
                              icon: LucideIcons.bookOpen,
                              label: 'Skills',
                              isSelected: currentIndex == 1,
                              onTap: () => _onTap(context, 1),
                            ),
                            _NavBarItem(
                              icon: LucideIcons.calendar,
                              label: 'Calendar',
                              isSelected: currentIndex == 2,
                              onTap: () => _onTap(context, 2),
                            ),
                            _NavBarItem(
                              icon: LucideIcons.trendingUp,
                              label: 'Progress',
                              isSelected: currentIndex == 3,
                              onTap: () => _onTap(context, 3),
                            ),
                            _NavBarItem(
                              icon: LucideIcons.moreHorizontal,
                              label: 'More',
                              isSelected: false,
                              hasBadge: totalUnread > 0,
                              onTap: () => _onTap(context, 4),
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
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool hasBadge;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    this.hasBadge = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = AppColors.primary;
    final inactiveColor = AppColors.textSecondary;

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
                  scale: isSelected ? 1.05 : 1.0,
                  child: Icon(
                    icon,
                    size: 19,
                    color: isSelected ? activeColor : inactiveColor,
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
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? activeColor : inactiveColor,
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

class _MoreMenuItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final int badgeCount;
  final VoidCallback onTap;

  const _MoreMenuItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.badgeCount = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (badgeCount > 0) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0x333B5B8C),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0x593B5B8C)),
                ),
                child: Text(
                  badgeCount > 99 ? '99+' : badgeCount.toString(),
                  style: const TextStyle(
                    color: Color(0xFF7E9ED4),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            const Icon(LucideIcons.chevronRight, color: AppColors.textMuted, size: 18),
          ],
        ),
      ),
    );
  }
}
