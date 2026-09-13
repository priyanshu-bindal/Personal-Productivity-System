import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../theme/app_colors.dart';
import '../theme/ocean_theme.dart';

class PremiumDropdownItem<T> {
  final T value;
  final String label;
  final IconData? icon;
  final Color? iconColor;

  const PremiumDropdownItem({
    required this.value,
    required this.label,
    this.icon,
    this.iconColor,
  });
}

class PremiumDropdownField<T> extends StatefulWidget {
  final String label;
  final T value;
  final List<PremiumDropdownItem<T>> items;
  final ValueChanged<T> onChanged;

  const PremiumDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  State<PremiumDropdownField<T>> createState() =>
      _PremiumDropdownFieldState<T>();
}

class _PremiumDropdownFieldState<T> extends State<PremiumDropdownField<T>>
    with SingleTickerProviderStateMixin {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 210),
      reverseDuration: const Duration(milliseconds: 160),
    );

    final curved = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(curved);
    _scaleAnimation = Tween<double>(begin: 0.96, end: 1.0).animate(curved);
  }

  @override
  void dispose() {
    _isOpen = false;
    if (_overlayEntry != null) {
      _overlayEntry?.remove();
      _overlayEntry = null;
    }
    _animController.dispose();
    super.dispose();
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    if (_isOpen) return;

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);
    final screenSize = MediaQuery.of(context).size;

    // Intelligent positioning: check if there is enough space below (needs ~240px)
    final spaceBelow = screenSize.height - (offset.dy + size.height);
    final openUpward = spaceBelow < 240 && offset.dy > spaceBelow;

    _overlayEntry = _createOverlayEntry(size, openUpward);
    Overlay.of(context).insert(_overlayEntry!);

    setState(() {
      _isOpen = true;
    });

    _animController.forward(from: 0.0);
  }

  void _closeDropdown({bool animate = true, VoidCallback? onComplete}) {
    if (!_isOpen && _overlayEntry == null) return;

    if (animate && mounted) {
      setState(() => _isOpen = false);
      _animController.reverse().then((_) {
        if (_overlayEntry != null) {
          _overlayEntry?.remove();
          _overlayEntry = null;
        }
        if (mounted) onComplete?.call();
      });
    } else {
      _isOpen = false;
      if (_overlayEntry != null) {
        _overlayEntry?.remove();
        _overlayEntry = null;
      }
      if (mounted) setState(() {});
      onComplete?.call();
    }
  }

  OverlayEntry _createOverlayEntry(Size targetSize, bool openUpward) {
    return OverlayEntry(
      builder: (context) {
        final curved = CurvedAnimation(
          parent: _animController,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        return Stack(
          children: [
            // Barrier to dismiss on tap outside
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => _closeDropdown(),
                child: const SizedBox.expand(),
              ),
            ),

            // Animated Dropdown Popover
            Positioned(
              width: targetSize.width,
              child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                targetAnchor: openUpward ? Alignment.topLeft : Alignment.bottomLeft,
                followerAnchor: openUpward ? Alignment.bottomLeft : Alignment.topLeft,
                offset: Offset(0, openUpward ? -4 : 4),
                child: AnimatedBuilder(
                  animation: _animController,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: Offset(0, openUpward ? 0.05 : -0.05),
                          end: Offset.zero,
                        ).animate(curved),
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          alignment: openUpward
                              ? Alignment.bottomCenter
                              : Alignment.topCenter,
                          child: child,
                        ),
                      ),
                    );
                  },
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 240),
                      decoration: BoxDecoration(
                        color: OceanTheme.cardHi,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.border.withValues(alpha: 0.9),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.65),
                            blurRadius: 22,
                            offset: const Offset(0, 8),
                          ),
                          BoxShadow(
                            color: AppColors.secondary.withValues(alpha: 0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            OceanTheme.cardHi,
                            OceanTheme.card,
                          ],
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          shrinkWrap: true,
                          physics: const BouncingScrollPhysics(),
                          itemCount: widget.items.length,
                          itemBuilder: (context, index) {
                            final item = widget.items[index];
                            final isSelected = item.value == widget.value;

                            return InkWell(
                              onTap: () {
                                _closeDropdown(
                                  animate: true,
                                  onComplete: () {
                                    widget.onChanged(item.value);
                                  },
                                );
                              },
                              splashColor: AppColors.secondary.withValues(alpha: 0.15),
                              highlightColor: AppColors.secondary.withValues(alpha: 0.10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.secondary.withValues(alpha: 0.14)
                                      : Colors.transparent,
                                ),
                                child: Row(
                                  children: [
                                    // Checkmark on the left for selected item
                                    SizedBox(
                                      width: 18,
                                      child: isSelected
                                          ? const Icon(
                                              LucideIcons.check,
                                              color: AppColors.blueHighlight,
                                              size: 15,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 8),

                                    // Optional item icon
                                    if (item.icon != null) ...[
                                      Icon(
                                        item.icon,
                                        size: 16,
                                        color: item.iconColor ??
                                            (isSelected
                                                ? AppColors.blueHighlight
                                                : AppColors.textSecondary),
                                      ),
                                      const SizedBox(width: 10),
                                    ],

                                    // Label
                                    Expanded(
                                      child: Text(
                                        item.label,
                                        style: TextStyle(
                                          color: isSelected
                                              ? AppColors.textPrimary
                                              : AppColors.textSecondary,
                                          fontSize: 13,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
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
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentItem = widget.items.firstWhere(
      (item) => item.value == widget.value,
      orElse: () => widget.items.first,
    );

    return CompositedTransformTarget(
      link: _layerLink,
      child: InkWell(
        onTap: _toggleDropdown,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: _isOpen
                ? OceanTheme.cardHi.withValues(alpha: 0.9)
                : OceanTheme.bg.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isOpen
                  ? AppColors.secondary.withValues(alpha: 0.75)
                  : AppColors.border,
              width: _isOpen ? 1.4 : 1.0,
            ),
            boxShadow: _isOpen
                ? [
                    BoxShadow(
                      color: AppColors.secondary.withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.textDim,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  if (currentItem.icon != null) ...[
                    Icon(
                      currentItem.icon,
                      size: 15,
                      color: currentItem.iconColor ?? AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      currentItem.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isOpen ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    child: const Icon(
                      LucideIcons.chevronDown,
                      color: AppColors.textDim,
                      size: 15,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
