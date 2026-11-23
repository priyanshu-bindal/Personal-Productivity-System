import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/oled_theme.dart';

/// iOS-style modal sheet used for every form in the app
/// (add skill, add note, add expense, set budget…).
///
/// - Slides in and out, with an optional inset layout for forms with an icon.
/// - Drag the handle/header down to dismiss (velocity aware).
/// - Rides on top of the keyboard.
class CustomBottomSheet {
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget child,
    String? subtitle,
    IconData? leadingIcon,
    Color accentColor = OledTheme.accent,
  }) {
    HapticFeedback.selectionClick();
    return Navigator.of(context, rootNavigator: true).push<T>(
      _SheetRoute<T>(
        reduceMotion: MediaQuery.disableAnimationsOf(context),
        barrierLabel: MaterialLocalizations.of(
          context,
        ).modalBarrierDismissLabel,
        pageBuilder: (context, animation, secondaryAnimation) => _SheetScaffold(
          title: title,
          subtitle: subtitle,
          leadingIcon: leadingIcon,
          accentColor: accentColor,
          animation: animation,
          child: child,
        ),
      ),
    );
  }
}

class _SheetRoute<T> extends RawDialogRoute<T> {
  _SheetRoute({
    required this.reduceMotion,
    required super.barrierLabel,
    required super.pageBuilder,
  }) : super(
         barrierColor: const Color(0xA6000000),
         transitionDuration: reduceMotion ? Duration.zero : AppMotion.sheetOpen,
         transitionBuilder: (_, _, _, child) => child,
       );

  final bool reduceMotion;

  @override
  Duration get reverseTransitionDuration =>
      reduceMotion ? Duration.zero : AppMotion.sheetClose;
}

class _SheetScaffold extends StatefulWidget {
  final String title;
  final String? subtitle;
  final IconData? leadingIcon;
  final Color accentColor;
  final Animation<double> animation;
  final Widget child;

  const _SheetScaffold({
    required this.title,
    required this.subtitle,
    required this.leadingIcon,
    required this.accentColor,
    required this.animation,
    required this.child,
  });

  @override
  State<_SheetScaffold> createState() => _SheetScaffoldState();
}

class _SheetScaffoldState extends State<_SheetScaffold>
    with SingleTickerProviderStateMixin {
  final ValueNotifier<double> _dragOffset = ValueNotifier<double>(0);
  late final AnimationController _settle;
  late final CurvedAnimation _transition;
  double _settleFrom = 0;

  @override
  void initState() {
    super.initState();
    _transition = AppMotion.curved(widget.animation);
    _settle = AnimationController(vsync: this, duration: AppMotion.standard)
      ..addListener(() {
        _dragOffset.value =
            _settleFrom * (1 - AppMotion.enter.transform(_settle.value));
      });
  }

  @override
  void dispose() {
    _transition.dispose();
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
    _resetDrag();
  }

  void _resetDrag() {
    if (MediaQuery.disableAnimationsOf(context)) {
      _dragOffset.value = 0;
    } else {
      _settleFrom = _dragOffset.value;
      _settle.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final keyboard = mq.viewInsets.bottom;
    final inset = widget.leadingIcon != null;
    final bottomGap = inset
        ? math.max(keyboard, mq.padding.bottom) + 12
        : keyboard;
    final bottomSafe = inset || keyboard > 0 ? 12.0 : mq.padding.bottom + 12.0;
    final maxHeight = math.max(
      0.0,
      mq.size.height - mq.padding.top - bottomGap - 16,
    );
    final compact = maxHeight < 200;

    final header = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragUpdate: _onDragUpdate,
      onVerticalDragEnd: _onDragEnd,
      onVerticalDragCancel: _resetDrag,
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
              crossAxisAlignment: inset
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                if (widget.leadingIcon case final icon?) ...[
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: widget.accentColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SizedBox.square(
                      dimension: 42,
                      child: Icon(icon, color: widget.accentColor, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          widget.title,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: inset ? 23 : 20,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
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
                IconButton(
                  tooltip: 'Close',
                  onPressed: _close,
                  style: IconButton.styleFrom(
                    backgroundColor: OledTheme.subtleSurface,
                  ),
                  icon: const Icon(
                    LucideIcons.x,
                    color: AppColors.textSecondary,
                    size: 17,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    final panel = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 560, maxHeight: maxHeight),
      child: Material(
        color: OledTheme.cardElevated,
        shape: RoundedRectangleBorder(
          borderRadius: inset
              ? BorderRadius.circular(26)
              : const BorderRadius.vertical(top: Radius.circular(26)),
          side: const BorderSide(color: OledTheme.borderHighlight),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!compact) header,
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (compact) header,
                    Padding(
                      padding: EdgeInsets.fromLTRB(20, 0, 20, bottomSafe),
                      child: widget.child,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
    final slide = SlideTransition(
      position: Tween<Offset>(
        begin: Offset(0, inset ? 0.24 : 1),
        end: Offset.zero,
      ).animate(_transition),
      child: panel,
    );

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          inset ? 12 : 0,
          0,
          inset ? 12 : 0,
          bottomGap,
        ),
        child: ValueListenableBuilder<double>(
          valueListenable: _dragOffset,
          builder: (context, dy, sheet) =>
              Transform.translate(offset: Offset(0, dy), child: sheet),
          child: inset
              ? FadeTransition(opacity: _transition, child: slide)
              : slide,
        ),
      ),
    );
  }
}
