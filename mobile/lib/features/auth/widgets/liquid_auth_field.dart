import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'liquid_theme.dart';

/// Reusable Dark Liquid Glass Text Field
///
/// Features:
/// - Dark translucent surface (rgba(15, 23, 42, 0.65))
/// - Stable 52px height
/// - Consistent 14px radius
/// - Smooth border color transition: Default (#26334A) → Focused (#2F6BFF) → Error (#EF4444)
/// - Stable border width (no layout jumps or border flashing)
/// - Subtle blue glow on focus
/// - Cursor in #2F6BFF
/// - Inline AnimatedSize error slot that gracefully expands without breaking layout
class LiquidAuthTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String label;
  final String? hintText;
  final IconData? prefixIcon;
  final bool isPassword;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? errorText;
  final FocusNode? focusNode;
  final Iterable<String>? autofillHints;

  const LiquidAuthTextField({
    super.key,
    this.controller,
    required this.label,
    this.hintText,
    this.prefixIcon,
    this.isPassword = false,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.onChanged,
    this.onSubmitted,
    this.errorText,
    this.focusNode,
    this.autofillHints,
  });

  @override
  State<LiquidAuthTextField> createState() => _LiquidAuthTextFieldState();
}

class _LiquidAuthTextFieldState extends State<LiquidAuthTextField> {
  late final FocusNode _effectiveFocusNode;
  bool _isFocused = false;
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _effectiveFocusNode = widget.focusNode ?? FocusNode();
    _effectiveFocusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _effectiveFocusNode.dispose();
    } else {
      _effectiveFocusNode.removeListener(_onFocusChange);
    }
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() => _isFocused = _effectiveFocusNode.hasFocus);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    // Border color logic
    final Color borderColor = hasError
        ? LiquidTheme.error
        : _isFocused
            ? LiquidTheme.borderFocused
            : LiquidTheme.border;

    // Background fill logic
    final Color fillColor = hasError
        ? const Color(0xB8140B13) // subtle tinted dark
        : _isFocused
            ? const Color(0xD90B1428) // slightly deeper blue-tinted navy
            : const Color(0xA60F172A); // rgba(15, 23, 42, 0.65)

    // Glow shadow on focus
    final List<BoxShadow> shadows = _isFocused && !hasError
        ? [
            const BoxShadow(
              color: Color(0x332F6BFF), // subtle blue glow
              blurRadius: 10,
              spreadRadius: 0,
              offset: Offset(0, 1),
            ),
          ]
        : hasError
            ? [
                const BoxShadow(
                  color: Color(0x28EF4444), // subtle red glow
                  blurRadius: 8,
                  spreadRadius: 0,
                  offset: Offset(0, 1),
                ),
              ]
            : const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Input Container ───────────────────────────────────────────
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          height: 52,
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: borderColor,
              width: _isFocused ? 1.2 : 1.0,
            ),
            boxShadow: shadows,
          ),
          child: Row(
            children: [
              // Prefix icon
              if (widget.prefixIcon != null)
                Padding(
                  padding: const EdgeInsets.only(left: 14, right: 10),
                  child: Icon(
                    widget.prefixIcon,
                    size: 18,
                    color: hasError
                        ? LiquidTheme.errorText
                        : _isFocused
                            ? LiquidTheme.primary
                            : LiquidTheme.textSecondary,
                  ),
                )
              else
                const SizedBox(width: 14),

              // Main text field
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _effectiveFocusNode,
                  obscureText: widget.isPassword ? _obscureText : false,
                  keyboardType: widget.keyboardType,
                  textInputAction: widget.textInputAction,
                  textCapitalization: widget.textCapitalization,
                  autofillHints: widget.autofillHints,
                  onChanged: widget.onChanged,
                  onSubmitted: widget.onSubmitted,
                  cursorColor: LiquidTheme.primary,
                  cursorWidth: 1.5,
                  style: LiquidTheme.inputText(fontSize: 14.5).copyWith(
                    color: LiquidTheme.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.hintText ?? widget.label,
                    hintStyle: LiquidTheme.inputLabel(fontSize: 14).copyWith(
                      color: LiquidTheme.textMuted,
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                  ),
                ),
              ),

              // Suffix toggle for password
              if (widget.isPassword)
                SizedBox(
                  width: 44,
                  height: 52,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        setState(() => _obscureText = !_obscureText);
                      },
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 150),
                          child: Icon(
                            _obscureText ? LucideIcons.eyeOff : LucideIcons.eye,
                            key: ValueKey<bool>(_obscureText),
                            size: 18,
                            color: _obscureText
                                ? LiquidTheme.textMuted
                                : LiquidTheme.secondaryBlue,
                          ),
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

        // ── Inline Error Message ──────────────────────────────────────
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topLeft,
          child: hasError
              ? Padding(
                  padding: const EdgeInsets.only(top: 5, left: 6, right: 6),
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.alertCircle,
                        size: 13,
                        color: LiquidTheme.errorText,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          widget.errorText!,
                          style: LiquidTheme.caption(color: LiquidTheme.errorText)
                              .copyWith(height: 1.3),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

/// Backward compatibility adapter so any existing code using LiquidGlassInput continues to work
class LiquidGlassInput extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final String? errorText;
  final double borderRadius;

  const LiquidGlassInput({
    super.key,
    this.controller,
    required this.label,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.onChanged,
    this.onFieldSubmitted,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.errorText,
    this.borderRadius = 14.0,
  });

  @override
  Widget build(BuildContext context) {
    return LiquidAuthTextField(
      controller: controller,
      label: label,
      prefixIcon: prefixIcon,
      isPassword: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      onChanged: onChanged,
      onSubmitted: onFieldSubmitted,
      errorText: errorText,
    );
  }
}
