import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/oled_theme.dart';

/// Auth text field — flat OLED surface, hairline border, crisp accent focus
/// ring (no glow). Label sits above; errors slide in underneath.
class GlassAuthFieldV2 extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String label;
  final String hintText;
  final IconData prefixIcon;
  final bool isPassword;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final TextCapitalization textCapitalization;
  final Iterable<String>? autofillHints;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const GlassAuthFieldV2({
    super.key,
    required this.controller,
    required this.label,
    required this.hintText,
    required this.prefixIcon,
    this.focusNode,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  State<GlassAuthFieldV2> createState() => _GlassAuthFieldV2State();
}

class _GlassAuthFieldV2State extends State<GlassAuthFieldV2> {
  FocusNode? _ownFocus;
  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode());
  bool _focused = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
  }

  @override
  void didUpdateWidget(GlassAuthFieldV2 oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _ownFocus)?.removeListener(_onFocus);
      _focus.addListener(_onFocus);
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    _ownFocus?.dispose();
    super.dispose();
  }

  void _onFocus() {
    if (_focused != _focus.hasFocus) setState(() => _focused = _focus.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null;
    final borderColor = hasError
        ? OledTheme.coral
        : (_focused ? OledTheme.accent : const Color(0xFF26262B));
    final iconColor = hasError
        ? OledTheme.coral
        : (_focused ? OledTheme.accent : OledTheme.textMuted);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 7),
          child: Text(
            widget.label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: OledTheme.textSecondary,
            ),
          ),
        ),
        AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.standardCurve,
          height: 54,
          decoration: BoxDecoration(
            color: _focused ? const Color(0xFF111114) : const Color(0xFF0C0C0E),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: _focused || hasError ? 1.3 : 1),
          ),
          child: Row(
            children: [
              const SizedBox(width: 14),
              TweenAnimationBuilder<Color?>(
                tween: ColorTween(end: iconColor),
                duration: AppMotion.fast,
                builder: (context, c, _) => Icon(widget.prefixIcon, size: 18, color: c),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focus,
                  obscureText: widget.isPassword && _obscure,
                  keyboardType: widget.keyboardType,
                  textInputAction: widget.textInputAction,
                  textCapitalization: widget.textCapitalization,
                  autofillHints: widget.autofillHints,
                  autocorrect: !widget.isPassword &&
                      widget.keyboardType != TextInputType.emailAddress,
                  enableSuggestions: !widget.isPassword,
                  onChanged: widget.onChanged,
                  onSubmitted: widget.onSubmitted,
                  cursorColor: OledTheme.accent,
                  cursorWidth: 1.6,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: OledTheme.textPrimary,
                  ),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    hintText: widget.hintText,
                    hintStyle: GoogleFonts.inter(
                      fontSize: 15,
                      color: const Color(0xFF55555C),
                    ),
                  ),
                ),
              ),
              if (widget.isPassword)
                Semantics(
                  button: true,
                  label: _obscure ? 'Show password' : 'Hide password',
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _obscure = !_obscure);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: AnimatedSwitcher(
                        duration: AppMotion.fast,
                        transitionBuilder: (child, a) =>
                            FadeTransition(opacity: a, child: ScaleTransition(scale: a, child: child)),
                        child: Icon(
                          _obscure ? LucideIcons.eye : LucideIcons.eyeOff,
                          key: ValueKey(_obscure),
                          size: 18,
                          color: OledTheme.textMuted,
                        ),
                      ),
                    ),
                  ),
                )
              else
                const SizedBox(width: 14),
            ],
          ),
        ),
        AnimatedSize(
          duration: AppMotion.fast,
          curve: AppMotion.standardCurve,
          alignment: Alignment.topLeft,
          child: hasError
              ? Padding(
                  padding: const EdgeInsets.only(top: 7, left: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 1),
                        child: Icon(LucideIcons.alertCircle, size: 13, color: OledTheme.coral),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.errorText!,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: OledTheme.coral,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}
