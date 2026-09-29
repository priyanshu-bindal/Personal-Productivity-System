import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Unified Glass Input Field V2.
/// Features:
/// - One single unified surface and outer border (NO nested rects or duplicate borders)
/// - Exact fixed height (52px) and radius (14px) across all states
/// - Smooth 180ms easeOutCubic focus transition
/// - Focus: #2F6BFF with subtle blue glow (strictly NO green, cyan, or teal)
/// - Integrated password visibility toggle on identical surface
/// - Animated error message underneath
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
    this.focusNode,
    required this.label,
    required this.hintText,
    required this.prefixIcon,
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
  late FocusNode _focusNode;
  bool _internalFocusNode = false;
  bool _isFocused = false;
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode != null) {
      _focusNode = widget.focusNode!;
    } else {
      _focusNode = FocusNode();
      _internalFocusNode = true;
    }
    _focusNode.addListener(_handleFocusChanged);
    _obscureText = widget.isPassword;
  }

  @override
  void didUpdateWidget(covariant GlassAuthFieldV2 oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      if (_internalFocusNode) {
        _focusNode.removeListener(_handleFocusChanged);
        _focusNode.dispose();
        _internalFocusNode = false;
      }
      if (widget.focusNode != null) {
        _focusNode = widget.focusNode!;
        _focusNode.addListener(_handleFocusChanged);
      } else {
        _focusNode = FocusNode();
        _internalFocusNode = true;
        _focusNode.addListener(_handleFocusChanged);
      }
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChanged);
    if (_internalFocusNode) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _handleFocusChanged() {
    if (mounted && _isFocused != _focusNode.hasFocus) {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    // Border and Shadow Colors
    final Color borderColor;
    final List<BoxShadow> shadows;
    final Color iconColor;

    if (hasError) {
      borderColor = const Color(0xFFFF5C68); // Soft destructive red
      shadows = const [
        BoxShadow(
          color: Color(0x22FF5C68),
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ];
      iconColor = const Color(0xFFFF5C68);
    } else if (_isFocused) {
      borderColor = const Color(0xFF2F6BFF); // FocusFlow primary blue
      shadows = const [
        BoxShadow(
          color: Color(0x302F6BFF), // Restrained subtle blue glow (no neon, no cyan)
          blurRadius: 10,
          spreadRadius: 0,
          offset: Offset(0, 2),
        ),
      ];
      iconColor = const Color(0xFF2F6BFF);
    } else {
      borderColor = const Color(0xFF1B2B48); // Subtle dark-blue border
      shadows = const [];
      iconColor = const Color(0xFF64748B); // Muted slate
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Field Label (Space Grotesk)
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            widget.label.toUpperCase(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11.0,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              color: hasError
                  ? const Color(0xFFFF5C68)
                  : _isFocused
                      ? const Color(0xFF94B8FF)
                      : const Color(0xFF7F91AA),
            ),
          ),
        ),

        // Single Unified Pill Input Field Container
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          height: 52, // Fixed height across all states
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF142036), // Subtle inner highlight at the top edge
                Color(0xFF091120), // Translucent deep navy core
              ],
            ),
            borderRadius: BorderRadius.circular(26), // Pill-like corners
            border: Border.all(
              color: borderColor,
              width: 1.2, // Fixed border width so dimensions never jump
            ),
            boxShadow: shadows,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26), // Proper internal clipping
            child: Row(
              children: [
                // Prefix Icon (Consistent alignment)
                Padding(
                  padding: const EdgeInsets.only(left: 18, right: 12),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    child: Icon(
                      widget.prefixIcon,
                      key: ValueKey<Color>(iconColor),
                      size: 18,
                      color: iconColor,
                    ),
                  ),
                ),

                // Text Input Area
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    focusNode: _focusNode,
                    obscureText: widget.isPassword && _obscureText,
                    keyboardType: widget.keyboardType,
                    textInputAction: widget.textInputAction,
                    textCapitalization: widget.textCapitalization,
                    autofillHints: widget.autofillHints,
                    cursorColor: const Color(0xFF2F6BFF),
                    cursorWidth: 1.5,
                    cursorRadius: const Radius.circular(1),
                    style: GoogleFonts.inter(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFFF1F5F9),
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 16,
                      ),
                      hintText: widget.hintText,
                      hintStyle: GoogleFonts.inter(
                        fontSize: 14.0,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF64748B), // Professional readable placeholder
                      ),
                    ),
                    onChanged: widget.onChanged,
                    onSubmitted: widget.onSubmitted,
                  ),
                ),

                // Optional Password Visibility Toggle
                if (widget.isPassword) ...[
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        setState(() {
                          _obscureText = !_obscureText;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 8,
                          right: 18,
                          top: 14,
                          bottom: 14,
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 150),
                          child: Icon(
                            _obscureText ? LucideIcons.eyeOff : LucideIcons.eye,
                            key: ValueKey<bool>(_obscureText),
                            size: 18,
                            color: const Color(0xFF7F91AA),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Animated Inline Error Message
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: hasError
              ? Padding(
                  padding: const EdgeInsets.only(left: 4, top: 5),
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.alertCircle,
                        size: 12,
                        color: Color(0xFFFF5C68),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          widget.errorText!,
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFFFF5C68),
                          ),
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
