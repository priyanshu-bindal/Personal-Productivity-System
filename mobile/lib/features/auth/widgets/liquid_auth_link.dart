import 'package:flutter/material.dart';
import 'liquid_theme.dart';

/// Interactive Link Text for Authentication
///
/// Features:
/// - Primary / secondary blue coloration (#4F7CFF)
/// - Generous touch target (min 44px height or padding)
/// - Subtle opacity feedback on press without layout shift
/// - No default underline
class LiquidAuthLink extends StatefulWidget {
  final String text;
  final VoidCallback onTap;
  final bool bold;
  final double fontSize;
  final Color? color;

  const LiquidAuthLink({
    super.key,
    required this.text,
    required this.onTap,
    this.bold = false,
    this.fontSize = 13.5,
    this.color,
  });

  @override
  State<LiquidAuthLink> createState() => _LiquidAuthLinkState();
}

class _LiquidAuthLinkState extends State<LiquidAuthLink> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 100),
          opacity: _isPressed ? 0.70 : 1.0,
          child: Text(
            widget.text,
            style: LiquidTheme.linkText(
              fontSize: widget.fontSize,
              bold: widget.bold,
            ).copyWith(
              color: widget.color ?? LiquidTheme.secondaryBlue,
            ),
          ),
        ),
      ),
    );
  }
}

/// Subtle "───── or ─────" divider for authentication forms
class LiquidAuthDivider extends StatelessWidget {
  final String label;

  const LiquidAuthDivider({
    super.key,
    this.label = 'or',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Divider(
            color: Color(0xFF26334A), // #26334A
            thickness: 1.0,
            height: 1.0,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.0),
          child: Text(
            label,
            style: LiquidTheme.caption(color: LiquidTheme.textMuted).copyWith(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Expanded(
          child: Divider(
            color: Color(0xFF26334A),
            thickness: 1.0,
            height: 1.0,
          ),
        ),
      ],
    );
  }
}
