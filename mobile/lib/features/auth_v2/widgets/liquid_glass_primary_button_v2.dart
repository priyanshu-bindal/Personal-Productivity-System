import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/oled_theme.dart';

/// Solid accent primary button. Press = quick scale + tone shift,
/// loading = label cross-fades into a spinner. No glow.
class LiquidGlassPrimaryButtonV2 extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  final IconData? trailingIcon;

  const LiquidGlassPrimaryButtonV2({
    super.key,
    required this.label,
    this.onTap,
    this.isLoading = false,
    this.trailingIcon,
  });

  @override
  State<LiquidGlassPrimaryButtonV2> createState() => _LiquidGlassPrimaryButtonV2State();
}

class _LiquidGlassPrimaryButtonV2State extends State<LiquidGlassPrimaryButtonV2> {
  bool _pressed = false;

  bool get _enabled => widget.onTap != null && !widget.isLoading;

  void _set(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final color = _pressed ? const Color(0xFF3F7BEA) : OledTheme.accent;

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _enabled ? (_) => _set(true) : null,
        onTapUp: _enabled ? (_) => _set(false) : null,
        onTapCancel: () => _set(false),
        onTap: _enabled
            ? () {
                HapticFeedback.lightImpact();
                widget.onTap!();
              }
            : null,
        child: AnimatedScale(
          scale: _pressed ? 0.975 : 1.0,
          duration: AppMotion.instant,
          curve: AppMotion.press,
          child: AnimatedContainer(
            duration: AppMotion.fast,
            height: 54,
            decoration: BoxDecoration(
              color: widget.isLoading ? OledTheme.accent.withValues(alpha: 0.75) : color,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: AnimatedSwitcher(
              duration: AppMotion.fast,
              switchInCurve: AppMotion.standardCurve,
              transitionBuilder: (child, a) => FadeTransition(
                opacity: a,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.9, end: 1).animate(a),
                  child: child,
                ),
              ),
              child: widget.isLoading
                  ? const SizedBox(
                      key: ValueKey('loading'),
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      key: const ValueKey('label'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.label,
                          style: GoogleFonts.inter(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: -0.1,
                          ),
                        ),
                        if (widget.trailingIcon != null) ...[
                          const SizedBox(width: 8),
                          Icon(widget.trailingIcon, size: 17, color: Colors.white),
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

/// Inline text link used across auth screens.
class AuthTextLink extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;
  final double fontSize;

  const AuthTextLink({
    super.key,
    required this.label,
    required this.onTap,
    this.color = OledTheme.accent,
    this.fontSize = 13.5,
  });

  @override
  State<AuthTextLink> createState() => _AuthTextLinkState();
}

class _AuthTextLinkState extends State<AuthTextLink> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: () {
          HapticFeedback.selectionClick();
          FocusManager.instance.primaryFocus?.unfocus();
          widget.onTap();
        },
        child: AnimatedOpacity(
          opacity: _pressed ? 0.5 : 1.0,
          duration: AppMotion.instant,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Text(
              widget.label,
              style: GoogleFonts.inter(
                fontSize: widget.fontSize,
                fontWeight: FontWeight.w600,
                color: widget.color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Error banner shared by auth forms.
class AuthErrorBanner extends StatelessWidget {
  final String? message;
  const AuthErrorBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: AppMotion.fast,
      curve: AppMotion.standardCurve,
      alignment: Alignment.topCenter,
      child: message == null
          ? const SizedBox(width: double.infinity)
          : Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: OledTheme.coral.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: OledTheme.coral.withValues(alpha: 0.28)),
              ),
              child: Text(
                message!,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFFFF9A9A),
                  height: 1.35,
                ),
              ),
            ),
    );
  }
}
