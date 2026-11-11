import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../navigation/app_shell_scope.dart';
import '../theme/oled_theme.dart';
import 'pressable_scale.dart';

/// AppBar leading control for screens that can be either a root tab or a
/// pushed page: shows a back chevron when there is something to pop,
/// otherwise a sidebar button.
class ShellLeadingButton extends StatelessWidget {
  const ShellLeadingButton({super.key});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter.maybeOf(context);
    final canPop = Navigator.of(context).canPop() || (router?.canPop() ?? false);
    final shell = AppShellScope.maybeOf(context);

    if (!canPop && shell == null) return const SizedBox.shrink();

    final icon = canPop ? LucideIcons.chevronLeft : LucideIcons.menu;
    return Center(
      child: PressableScale(
        onTap: () {
          if (canPop) {
            Navigator.of(context).maybePop();
          } else {
            shell?.openSidebar();
          }
        },
        child: Semantics(
          button: true,
          label: canPop ? 'Back' : 'Open sidebar',
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: OledTheme.cardElevated,
              shape: BoxShape.circle,
              border: Border.all(color: OledTheme.border),
            ),
            child: Icon(icon, size: 18, color: OledTheme.textPrimary),
          ),
        ),
      ),
    );
  }
}
