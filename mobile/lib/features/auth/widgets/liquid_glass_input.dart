import 'package:flutter/material.dart';
import 'liquid_theme.dart';

/// Reusable Liquid Glass Input Field Component
///
/// Error state uses a soft pink-coral palette (#FF6B9D) that blends
/// naturally with the blue/cyan Liquid Glass theme — not harsh red.
///
/// State transitions:
///   normal  →  focused   : 200ms easeOutCubic — cyan border + glow
///   normal  →  error     : 200ms easeOutCubic — pink border + soft glow
///   focused →  error     : 200ms easeOutCubic
///   error   →  focused   : 200ms easeOutCubic (returns to cyan)
///
/// Layout: fixed 58px height + reserved 20px below for error text
/// (hidden with Opacity) to avoid layout jumps.
class LiquidGlassInput extends StatefulWidget {
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
    this.borderRadius = 28.0,
  });

  @override
  State<LiquidGlassInput> createState() => _LiquidGlassInputState();
}

class _LiquidGlassInputState extends State<LiquidGlassInput> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (mounted) {
        setState(() => _isFocused = _focusNode.hasFocus);
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  // ─── Derived state helpers ──────────────────────────────────────
  bool get _hasError => widget.errorText != null;

  // Border gradient: normal → focused → error
  Gradient get _borderGradient {
    if (_hasError) {
      return LinearGradient(
        colors: [
          LiquidTheme.error,                          // #FF6B9D
          LiquidTheme.error.withValues(alpha: 0.70),
          LiquidTheme.errorGlow.withValues(alpha: 0.50),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    if (_isFocused) {
      return const LinearGradient(
        colors: [
          LiquidTheme.cyan,     // #20D9FF focused bright
          LiquidTheme.primary,  // #168BFF
          LiquidTheme.iceBlue,  // #8BE8FF
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    // Normal (rest)
    return LinearGradient(
      colors: [
        LiquidTheme.glassBorder,                         // rgba(255,255,255,0.18)
        LiquidTheme.primary.withValues(alpha: 0.18),
        LiquidTheme.glassBorder,
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  // Glow: focused = cyan, error = pink, normal = none
  List<BoxShadow> get _shadows {
    if (_hasError) {
      return [
        BoxShadow(
          color: LiquidTheme.errorGlow.withValues(alpha: 0.22), // Very soft pink
          blurRadius: 14,
          spreadRadius: 0,
          offset: const Offset(0, 2),
        ),
        const BoxShadow(
          color: Color(0x33000000),
          blurRadius: 8,
          offset: Offset(0, 3),
        ),
      ];
    }
    if (_isFocused) {
      return [
        BoxShadow(
          color: LiquidTheme.cyan.withValues(alpha: 0.30),
          blurRadius: 16,
          spreadRadius: 0,
          offset: const Offset(0, 2),
        ),
        const BoxShadow(
          color: Color(0x33000000),
          blurRadius: 8,
          offset: Offset(0, 3),
        ),
      ];
    }
    return [
      const BoxShadow(
        color: Color(0x26000000),
        blurRadius: 8,
        offset: Offset(0, 3),
      ),
    ];
  }

  // Prefix icon color: error = pink, focused = cyan, normal = ice-blue muted
  Color get _iconColor {
    if (_hasError) return LiquidTheme.error; // #FF6B9D
    if (_isFocused) return LiquidTheme.cyan; // #20D9FF
    return LiquidTheme.iceBlue.withValues(alpha: 0.60); // muted ice blue
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Input pill (fixed 58px, no height change on error) ────────
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          height: 58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: _shadows,
            gradient: _borderGradient,
          ),
          child: Padding(
            padding: const EdgeInsets.all(1.2), // 1px glass border
            child: Container(
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(widget.borderRadius - 1.2),
                color: LiquidTheme.secondaryBackground
                    .withValues(alpha: 0.72), // #06142B glass base
              ),
              child: Row(
                children: [
                  // Prefix icon (21px, color-animated)
                  if (widget.prefixIcon != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 18, right: 12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        child: Icon(
                          widget.prefixIcon,
                          color: _iconColor,
                          size: 21,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 18),

                  // Text field (16px Inter)
                  Expanded(
                    child: Center(
                      child: TextFormField(
                        controller: widget.controller,
                        focusNode: _focusNode,
                        obscureText: widget.obscureText,
                        keyboardType: widget.keyboardType,
                        textInputAction: widget.textInputAction,
                        textCapitalization: widget.textCapitalization,
                        onChanged: widget.onChanged,
                        onFieldSubmitted: widget.onFieldSubmitted,
                        style: LiquidTheme.inputText(fontSize: 16),
                        cursorColor: _hasError
                            ? LiquidTheme.error
                            : LiquidTheme.cyan,
                        decoration: InputDecoration(
                          hintText: widget.label,
                          hintStyle: LiquidTheme.inputLabel(fontSize: 15)
                              .copyWith(
                            color: LiquidTheme.textSecondary,
                          ),
                          isDense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 16),
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                        ),
                      ),
                    ),
                  ),

                  // Suffix icon (eye toggle, etc.)
                  if (widget.suffixIcon != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: widget.suffixIcon,
                    )
                  else
                    const SizedBox(width: 18),
                ],
              ),
            ),
          ),
        ),

        // ── Error text (reserved 20px space — no layout jump) ─────────
        // Uses Opacity to show/hide so height is always reserved.
        AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          opacity: _hasError ? 1.0 : 0.0,
          child: Padding(
            padding: const EdgeInsets.only(top: 6, left: 18),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 12,
                  color: LiquidTheme.errorText, // #FF9FBC
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    // Show actual text or empty string to keep height
                    widget.errorText ?? '',
                    style: LiquidTheme.caption(
                      color: LiquidTheme.errorText, // #FF9FBC subtle pink
                    ).copyWith(
                      fontWeight: FontWeight.w400,
                      height: 1.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
