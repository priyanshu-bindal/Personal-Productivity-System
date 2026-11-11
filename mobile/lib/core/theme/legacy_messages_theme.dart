import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Frozen copy of the app theme as it was before the OLED redesign.
///
/// The Messages feature is intentionally left untouched by the redesign, so
/// its routes are wrapped in this theme to keep every Material default
/// (inputs, FAB shape, snackbars, dialogs, sheets) exactly as before.
class LegacyMessagesTheme {
  LegacyMessagesTheme._();

  static const Color _bg = Color(0xFF000000);
  static const Color _surface = Color(0xFF151E2B);
  static const Color _card = Color(0xFF0B1018);
  static const Color _border = Color(0xFF202B38);
  static const Color _primary = Color(0xFF20D6A1);
  static const Color _secondary = Color(0xFF5B8CFF);
  static const Color _error = Color(0xFFFF7D87);
  static const Color _textPrimary = Color(0xFFF4F7FB);
  static const Color _oceanText = Color(0xFFEAF2F5);
  static const Color _oceanDim = Color(0xFF7E93A8);
  static const Color _oceanFaint = Color(0xFF4C5E70);

  static final ThemeData data = _build();

  static ThemeData _build() {
    final title = GoogleFonts.spaceGrotesk(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: _oceanText,
      letterSpacing: -0.5,
      height: 1.3,
    );
    final bodySecondary = GoogleFonts.inter(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: _oceanDim,
      height: 1.35,
    );
    final bodyMedium = GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: _oceanText,
      height: 1.35,
    );
    final buttonText = GoogleFonts.inter(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: _bg,
      height: 1.2,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _bg,
      colorScheme: const ColorScheme.dark(
        surface: _surface,
        primary: _primary,
        secondary: _secondary,
        error: _error,
        onSurface: _textPrimary,
        onPrimary: _bg,
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme.copyWith(
              displayLarge: GoogleFonts.spaceGrotesk(
                fontSize: 52,
                fontWeight: FontWeight.w700,
                color: _oceanText,
                letterSpacing: -1.0,
                height: 1.1,
              ),
              displayMedium: title,
              titleLarge: title,
              titleMedium: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _oceanText,
                letterSpacing: -0.3,
                height: 1.3,
              ),
              bodyLarge: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _oceanText,
                height: 1.35,
              ),
              bodyMedium: bodyMedium,
              bodySmall: bodySecondary,
              labelSmall: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: _oceanFaint,
                height: 1.35,
              ),
            ),
      ),
      cardTheme: CardThemeData(
        color: _card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _border, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: bodySecondary,
        labelStyle: bodyMedium,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _error),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: _bg,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _textPrimary,
          side: const BorderSide(color: _border),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: buttonText.copyWith(color: _textPrimary),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: _surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: _surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: _border,
        thickness: 1,
        space: 1,
      ),
    );
  }
}

/// A [MaterialPage] whose route always uses the platform's stock Material
/// transition, ignoring the app-wide [PageTransitionsTheme]. Used for the
/// Messages routes so their push/pop animation stays exactly as before.
class PlatformDefaultPage<T> extends MaterialPage<T> {
  const PlatformDefaultPage({required super.child, super.key});

  @override
  Route<T> createRoute(BuildContext context) => _PlatformDefaultRoute<T>(this);
}

class _PlatformDefaultRoute<T> extends PageRoute<T>
    with MaterialRouteTransitionMixin<T> {
  _PlatformDefaultRoute(PlatformDefaultPage<T> page) : super(settings: page);

  PlatformDefaultPage<T> get _page => settings as PlatformDefaultPage<T>;

  @override
  Widget buildContent(BuildContext context) =>
      Theme(data: LegacyMessagesTheme.data, child: _page.child);

  @override
  bool get maintainState => _page.maintainState;

  @override
  bool get fullscreenDialog => _page.fullscreenDialog;

  @override
  String get debugLabel => '${super.debugLabel}(${_page.name})';

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return const PageTransitionsTheme()
        .buildTransitions<T>(this, context, animation, secondaryAnimation, child);
  }
}
