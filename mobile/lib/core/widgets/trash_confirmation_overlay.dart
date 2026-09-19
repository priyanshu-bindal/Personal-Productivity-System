import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../theme/ocean_theme.dart';
import 'pressable_scale.dart';

/// Unified compact floating FocusFlow confirmation overlay.
///
/// Supports:
/// - Soft-delete confirmation with immediate Undo: [show]
/// - Success feedback (e.g. "Expense restored", "Expense permanently deleted"): [showSuccess]
/// - Failure / Error feedback: [showError]
class TrashConfirmationOverlay {
  static OverlayEntry? _currentEntry;
  static Timer? _autoDismissTimer;

  /// Displays the floating confirmation card with an "Undo" action.
  /// Automatically dismisses after [duration] (default 3.5s).
  static void show({
    required BuildContext context,
    String message = 'Moved to Trash',
    required VoidCallback onUndo,
    Duration duration = const Duration(milliseconds: 3500),
  }) {
    _insertOverlay(
      context: context,
      message: message,
      onUndo: onUndo,
      duration: duration,
      icon: LucideIcons.check,
      iconColor: AppColors.primary,
      isError: false,
    );
  }

  /// Displays a success confirmation card (e.g. "Expense restored").
  /// Automatically dismisses after [duration] (default 2.8s).
  static void showSuccess({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(milliseconds: 2800),
    IconData icon = LucideIcons.check,
    Color? iconColor,
  }) {
    _insertOverlay(
      context: context,
      message: message,
      duration: duration,
      icon: icon,
      iconColor: iconColor ?? AppColors.primary,
      isError: false,
    );
  }

  /// Displays an error confirmation card (e.g. "Couldn't restore expense").
  /// Automatically dismisses after [duration] (default 3.2s).
  static void showError({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(milliseconds: 3200),
  }) {
    _insertOverlay(
      context: context,
      message: message,
      duration: duration,
      icon: LucideIcons.alertCircle,
      iconColor: AppColors.error,
      isError: true,
    );
  }

  static void _insertOverlay({
    required BuildContext context,
    required String message,
    VoidCallback? onUndo,
    required Duration duration,
    required IconData icon,
    required Color iconColor,
    required bool isError,
  }) {
    hideCurrent();

    final overlayState = Overlay.maybeOf(context, rootOverlay: true);
    if (overlayState == null) return;

    final cardKey = GlobalKey<_TrashConfirmationCardState>();

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _TrashConfirmationCard(
        key: cardKey,
        message: message,
        icon: icon,
        iconColor: iconColor,
        isError: isError,
        onUndo: onUndo == null
            ? null
            : () {
                _autoDismissTimer?.cancel();
                _autoDismissTimer = null;
                cardKey.currentState?.dismiss(onDismissed: () {
                  if (_currentEntry == entry) {
                    hideCurrent();
                  }
                  onUndo();
                });
              },
      ),
    );

    _currentEntry = entry;
    overlayState.insert(entry);

    _autoDismissTimer = Timer(duration, () {
      cardKey.currentState?.dismiss(onDismissed: () {
        if (_currentEntry == entry) {
          hideCurrent();
        }
      });
    });
  }

  /// Immediately removes any active confirmation card.
  static void hideCurrent() {
    _autoDismissTimer?.cancel();
    _autoDismissTimer = null;
    if (_currentEntry != null) {
      try {
        _currentEntry?.remove();
      } catch (_) {}
      _currentEntry = null;
    }
  }
}

class _TrashConfirmationCard extends StatefulWidget {
  final String message;
  final VoidCallback? onUndo;
  final IconData icon;
  final Color iconColor;
  final bool isError;

  const _TrashConfirmationCard({
    super.key,
    required this.message,
    this.onUndo,
    required this.icon,
    required this.iconColor,
    required this.isError,
  });

  @override
  State<_TrashConfirmationCard> createState() => _TrashConfirmationCardState();
}

class _TrashConfirmationCardState extends State<_TrashConfirmationCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _iconScaleAnimation;
  late final Animation<double> _iconFadeAnimation;

  bool _isDismissing = false;
  bool _undoTapped = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      reverseDuration: const Duration(milliseconds: 200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));

    // Icon subtle scale 0.8 -> 1.0 + fade
    _iconScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.15, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _iconFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 0.85, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      _controller.value = 1.0;
    } else if (!_controller.isAnimating && !_controller.isCompleted) {
      _controller.forward();
    }
  }

  void dismiss({VoidCallback? onDismissed}) {
    if (_isDismissing) return;
    _isDismissing = true;
    if (!mounted) {
      onDismissed?.call();
      return;
    }
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      onDismissed?.call();
      return;
    }
    _controller.reverse().then((_) {
      if (mounted) {
        onDismissed?.call();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final iconBgColor = widget.iconColor.withValues(alpha: 0.15);
    final iconBorderColor = widget.iconColor.withValues(alpha: 0.35);

    return Positioned(
      bottom: bottomPadding + 20,
      left: 16,
      right: 16,
      child: Material(
        type: MaterialType.transparency,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: OceanTheme.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.isError
                      ? AppColors.error.withValues(alpha: 0.4)
                      : AppColors.border,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  FadeTransition(
                    opacity: _iconFadeAnimation,
                    child: ScaleTransition(
                      scale: _iconScaleAnimation,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: iconBgColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: iconBorderColor,
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          widget.icon,
                          size: 15,
                          color: widget.iconColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ),
                  if (widget.onUndo != null) ...[
                    PressableScale(
                      scaleFactor: 0.94,
                      onTap: () {
                        if (_undoTapped) return;
                        _undoTapped = true;
                        widget.onUndo!();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            width: 1,
                          ),
                        ),
                        child: const Text(
                          'Undo',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
