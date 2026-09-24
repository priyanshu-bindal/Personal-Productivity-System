import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'widgets/liquid_theme.dart';
import 'widgets/liquid_background.dart';
import 'widgets/liquid_glass_button.dart';
import 'widgets/focusflow_logo.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeIn;
  late final Animation<double> _slideIn;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeIn = CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );
    _slideIn = CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.1, 0.9, curve: Curves.easeOutCubic),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _navigateToLogin() {
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.of(context).disableAnimations;
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: LiquidTheme.background,
      body: Stack(
        children: [
          // Animated continuous liquid background
          Positioned.fill(
            child: LiquidBackground(reducedMotion: reducedMotion),
          ),

          // Main content
          SafeArea(
            child: AnimatedBuilder(
              animation: _fadeController,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeIn.value,
                  child: Transform.translate(
                    offset: Offset(0, 18 * (1 - _slideIn.value)),
                    child: child,
                  ),
                );
              },
              child: Column(
                children: [
                  // Center scrollable content
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          SizedBox(height: screenHeight * 0.025),

                          // Brand Logo with glowing liquid icon
                          const FocusFlowLogo(size: 84),

                          const SizedBox(height: 28),

                          // Hero Headline
                          Text(
                            'A Better You',
                            textAlign: TextAlign.center,
                            style: LiquidTheme.heroHeading(fontSize: 32),
                          ),
                          const SizedBox(height: 2),
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [
                                LiquidTheme.cyan,
                                LiquidTheme.electricBlue,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ).createShader(bounds),
                            child: Text(
                              'Every Day',
                              textAlign: TextAlign.center,
                              style: LiquidTheme.heroHeading(fontSize: 32),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Subtitle
                          Text(
                            'Plan smarter, track your progress,\nand build the habits that matter.',
                            textAlign: TextAlign.center,
                            style: LiquidTheme.subtitle(fontSize: 14),
                          ),

                          const SizedBox(height: 32),

                          // 3 Liquid Glass Feature Cards (Plan, Track, Grow)
                          const _FeatureCardsRow(),

                          const SizedBox(height: 36),

                          // Primary Liquid Glass CTA
                          LiquidGlassButton(
                            label: 'Get Started',
                            icon: Icons.arrow_forward,
                            onTap: _navigateToLogin,
                          ),

                          // Generous bottom spacing without pagination dots
                          SizedBox(height: bottomPadding + 28),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// ─── Feature Cards Row ─────────────────────────────────────────
class _FeatureCardsRow extends StatelessWidget {
  const _FeatureCardsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: _FeatureCard(
            icon: Icons.checklist_rounded,
            title: 'Plan',
            subtitle: 'Organize\nyour tasks',
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _FeatureCard(
            icon: Icons.bar_chart_rounded,
            title: 'Track',
            subtitle: 'See your\nprogress',
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _FeatureCard(
            icon: LucideIcons.sprout,
            title: 'Grow',
            subtitle: 'Build a\nbetter you',
          ),
        ),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      decoration: BoxDecoration(
        color: LiquidTheme.cardSurface.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: LiquidTheme.electricBlue.withValues(alpha: 0.22),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: LiquidTheme.electricBlue.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
          const BoxShadow(
            color: Color(0x59000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: LiquidTheme.electricBlue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: LiquidTheme.cyan.withValues(alpha: 0.25),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: LiquidTheme.cyan.withValues(alpha: 0.15),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 26,
              color: LiquidTheme.cyan,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: LiquidTheme.cardTitle(fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: LiquidTheme.cardSubtitle(fontSize: 11),
          ),
        ],
      ),
    );
  }
}
