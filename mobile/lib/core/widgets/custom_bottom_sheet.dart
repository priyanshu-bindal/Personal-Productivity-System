import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/oled_theme.dart';

/// iOS-style modal sheet used for every form in the app
/// (add skill, add note, add expense, set budget…).
///
/// - Slides up from the bottom with a long, soft deceleration; closes with a
///   quicker settle. Only `transform` animates, so it stays smooth on slow
///   phones even while the keyboard is opening.
/// - Drag the handle/header down to dismiss (velocity aware).
/// - Rides on top of the keyboard.
class CustomBottomSheet {
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget child,
    String? subtitle,
  }) {
    HapticFeedback.selectionClick();
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.62),
      transitionDuration: AppMotion.sheetOpen,
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return _SheetScaffold(
          title: title,
          subtitle: subtitle,
          child: child,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, sheet) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
              .animate(AppMotion.curved(animation)),
          child: sheet,
        );
      },
    );
  }
}

class _SheetScaffold extends StatefulWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const _SheetScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  State<_SheetScaffold> createState() => _SheetScaffoldState();
}

class _SheetScaffoldState extends State<_SheetScaffold>
    with SingleTickerProviderStateMixin {
  final ValueNotifier<double> _dragOffset = ValueNotifier<double>(0);
  late final AnimationController _settle;
  double _settleFrom = 0;

  @override
  void initState() {
    super.initState();
    _settle = AnimationController(vsync: this, duration: AppMotion.standard)
      ..addListener(() {
        _dragOffset.value =
            _settleFrom * (1 - AppMotion.enter.transform(_settle.value));
      });
  }

  @override
  void dispose() {
    _settle.dispose();
    _dragOffset.dispose();
    super.dispose();
  }

  void _close() {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).maybePop();
  }

  void _onDragUpdate(DragUpdateDetails d) {
    _settle.stop();
    // Resist upward drags; follow downward drags 1:1.
    final next = _dragOffset.value + d.delta.dy;
    _dragOffset.value = next < 0 ? next * 0.2 : next;
  }

  void _onDragEnd(DragEndDetails d) {
    final v = d.velocity.pixelsPerSecond.dy;
    if (_dragOffset.value > 110 || v > 800) {
      _close();
      return;
    }
    _settleFrom = _dragOffset.value;
    _settle.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final keyboard = mq.viewInsets.bottom;
    final bottomSafe = keyboard > 0 ? 12.0 : mq.padding.bottom + 12.0;
    final maxHeight = (mq.size.height - mq.padding.top - keyboard - 24)
        .clamp(200.0, mq.size.height * 0.92);

    final header = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragUpdate: _onDragUpdate,
      onVerticalDragEnd: _onDragEnd,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 14, 0),
        child: Column(
          children: [
            Container(
              width: 38,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0x33FFFFFF),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.4,
                        ),
                      ),
                      if (widget.subtitle != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          widget.subtitle!,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Semantics(
                  button: true,
                  label: 'Close',
                  child: GestureDetector(
                    onTap: _close,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: OledTheme.subtleSurface,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.x,
                        color: AppColors.textSecondary,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.only(bottom: keyboard),
        child: ValueListenableBuilder<double>(
          valueListenable: _dragOffset,
          builder: (context, dy, sheet) =>
              Transform.translate(offset: Offset(0, dy), child: sheet),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 560, maxHeight: maxHeight),
            child: Material(
              color: OledTheme.cardElevated,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
                side: BorderSide(color: OledTheme.border, width: 0.8),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  header,
                  Flexible(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(20, 0, 20, bottomSafe),
                      child: widget.child,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
