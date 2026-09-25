import 'dart:ui';
import 'package:flutter/material.dart';
import 'liquid_theme.dart';

/// Liquid Glass Input Field — Premium Pill Design
///
/// Visual language matches the reference:
/// • Full capsule shape (borderRadius 30)
/// • Dark navy translucent glass fill
/// • Rim-lit gradient border — bright cyan sweep on the top-left arc
/// • Subtle outer glow on focus / error
/// • Icon + hint text centred inside the pill
///
/// State transitions (200 ms easeOutCubic):
///   normal  → focused   : bright cyan border sweep + outer glow
///   normal  → error     : soft pink border + pink glow
///   focused → error     : pink
///   error   → focused   : returns to cyan
///
/// A fixed 20 px error-text slot below prevents layout jumps.
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
    this.borderRadius = 30.0,
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
      if (mounted) setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  // ─── State helpers ─────────────────────────────────────────────
  bool get _hasError => widget.errorText != null;

  // ─── Rim-lit border gradient ───────────────────────────────────
  // Normal : a single bright sweep from top-left (like the reference photo)
  //          — start bright cyan at low opacity, fade to near-transparent
  // Focused: full bright cyan sweep (higher opacity)
  // Error  : pink sweep
  Gradient get _borderGradient {
    if (_hasError) {
      return LinearGradient(
        colors: [
          LiquidTheme.error,
          LiquidTheme.error.withValues(alpha: 0.55),
          LiquidTheme.errorGlow.withValues(alpha: 0.20),
        ],
        stops: const [0.0, 0.45, 1.0],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    if (_isFocused) {
      return LinearGradient(
        colors: [
          LiquidTheme.cyan,
          LiquidTheme.primary.withValues(alpha: 0.75),
          LiquidTheme.primary.withValues(alpha: 0.15),
          LiquidTheme.glassBorder,
        ],
        stops: const [0.0, 0.30, 0.65, 1.0],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    // Normal — resting: bright top-left sweep, dims toward bottom-right
    return LinearGradient(
      colors: [
        const Color(0xFF4EB3E8).withValues(alpha: 0.70), // bright ice rim
        const Color(0xFF2E7FBF).withValues(alpha: 0.40),
        const Color(0xFF1A4A78).withValues(alpha: 0.20),
        LiquidTheme.glassBorder.withValues(alpha: 0.08),
      ],
      stops: const [0.0, 0.25, 0.55, 1.0],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  // ─── Outer glow (focused / error) ──────────────────────────────
  List<BoxShadow> get _shadows {
    if (_hasError) {
      return [
        BoxShadow(
          color: LiquidTheme.error.withValues(alpha: 0.18),
          blurRadius: 18,
          spreadRadius: 1,
        ),
        const BoxShadow(
          color: Color(0x33000000),
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ];
    }
    if (_isFocused) {
      return [
        BoxShadow(
          color: LiquidTheme.cyan.withValues(alpha: 0.28),
          blurRadius: 20,
          spreadRadius: 0,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: LiquidTheme.primary.withValues(alpha: 0.12),
          blurRadius: 8,
          spreadRadius: 1,
        ),
        const BoxShadow(
          color: Color(0x33000000),
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ];
    }
    // Normal — subtle depth shadow, no glow
    return [
      const BoxShadow(
        color: Color(0x30000000),
        blurRadius: 12,
        offset: Offset(0, 4),
      ),
      const BoxShadow(
        color: Color(0x14000000),
        blurRadius: 4,
        offset: Offset(0, 2),
      ),
    ];
  }

  // ─── Fill color ────────────────────────────────────────────────
  // The reference shows a rich dark-blue tint — slightly more saturated
  // than pure #06142B. We layer a subtle blue tint on top.
  Color get _fillColor {
    if (_hasError) return const Color(0xFF0B1525).withValues(alpha: 0.88);
    if (_isFocused) return const Color(0xFF0A1E3D).withValues(alpha: 0.90);
    return const Color(0xFF081629).withValues(alpha: 0.85);
  }

  // ─── Icon color ────────────────────────────────────────────────
  Color get _iconColor {
    if (_hasError) return LiquidTheme.error;
    if (_isFocused) return LiquidTheme.cyan;
    // Reference: icons are a bright, solid blue-white — not muted
    return const Color(0xFF7EC8F0);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Pill container ─────────────────────────────────────────
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          height: 58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: _shadows,
            // Gradient border rendered as the outer shell
            gradient: _borderGradient,
          ),
          child: Padding(
            // Border thickness: 1.4px on normal, slightly more visible
            padding: const EdgeInsets.all(1.2),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.borderRadius - 1.2),
                color: _fillColor,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(widget.borderRadius - 1.2),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: _PillContent(
                    isFocused: _isFocused,
                    hasError: _hasError,
                    iconColor: _iconColor,
                    prefixIcon: widget.prefixIcon,
                    suffixIcon: widget.suffixIcon,
                    controller: widget.controller,
                    focusNode: _focusNode,
                    obscureText: widget.obscureText,
                    keyboardType: widget.keyboardType,
                    textInputAction: widget.textInputAction,
                    textCapitalization: widget.textCapitalization,
                    onChanged: widget.onChanged,
                    onFieldSubmitted: widget.onFieldSubmitted,
                    label: widget.label,
                  ),
                ),
              ),
            ),
          ),
        ),

        // ── Error text (reserved slot — no layout jump) ───────────
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
                  color: LiquidTheme.errorText,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    widget.errorText ?? '',
                    style: LiquidTheme.caption(color: LiquidTheme.errorText)
                        .copyWith(fontWeight: FontWeight.w400, height: 1.3),
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

// ─── Inner Pill Row ──────────────────────────────────────────────────────────
// Extracted so AnimatedContainer can independently animate fill vs content.
class _PillContent extends StatelessWidget {
  final bool isFocused;
  final bool hasError;
  final Color iconColor;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final TextEditingController? controller;
  final FocusNode focusNode;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final String label;

  const _PillContent({
    required this.isFocused,
    required this.hasError,
    required this.iconColor,
    required this.prefixIcon,
    required this.suffixIcon,
    required this.controller,
    required this.focusNode,
    required this.obscureText,
    required this.keyboardType,
    required this.textInputAction,
    required this.textCapitalization,
    required this.onChanged,
    required this.onFieldSubmitted,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // ── Prefix icon ───────────────────────────────────────────
        if (prefixIcon != null)
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 13),
            child: Icon(
              prefixIcon,
              color: iconColor,
              size: 20,
            ),
          )
        else
          const SizedBox(width: 20),

        // ── Text field ────────────────────────────────────────────
        Expanded(
          child: Center(
            child: TextFormField(
              controller: controller,
              focusNode: focusNode,
              obscureText: obscureText,
              keyboardType: keyboardType,
              textInputAction: textInputAction,
              textCapitalization: textCapitalization,
              onChanged: onChanged,
              onFieldSubmitted: onFieldSubmitted,
              style: LiquidTheme.inputText(fontSize: 15.5).copyWith(
                color: LiquidTheme.textPrimary,
                letterSpacing: 0.1,
              ),
              cursorColor: hasError ? LiquidTheme.error : LiquidTheme.cyan,
              cursorWidth: 1.5,
              decoration: InputDecoration(
                hintText: label,
                hintStyle: LiquidTheme.inputLabel(fontSize: 15).copyWith(
                  color: const Color(0xFF7A9BBF), // muted blue-gray hint
                  fontWeight: FontWeight.w400,
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 18),
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
              ),
            ),
          ),
        ),

        // ── Suffix icon ───────────────────────────────────────────
        if (suffixIcon != null)
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: IconTheme(
              data: IconThemeData(
                color: const Color(0xFF5A7FA8), // muted blue-gray for suffix
                size: 20,
              ),
              child: suffixIcon!,
            ),
          )
        else
          const SizedBox(width: 20),
      ],
    );
  }
}
