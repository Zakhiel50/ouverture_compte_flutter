import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';

/// Widget réutilisable pour basculer dynamiquement entre le Mode Clair et le Mode Sombre.
/// 
/// Utilisable directement dans un `AppBar.actions` ou n'importe quel écran.
class ThemeToggleButton extends ConsumerWidget {
  final bool showLabel;
  final EdgeInsetsGeometry? padding;
  final Color? activeColor;

  const ThemeToggleButton({
    super.key,
    this.showLabel = false,
    this.padding,
    this.activeColor,
  });

  /// Constructeur alternatif affichant un Switch nommé avec libellé
  const factory ThemeToggleButton.labeled({
    Key? key,
    EdgeInsetsGeometry? padding,
    Color? activeColor,
  }) = _LabeledThemeToggleButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Tooltip(
      message: isDark ? "Basculer en Mode Clair" : "Basculer en Mode Sombre",
      child: IconButton(
        padding: padding ?? const EdgeInsets.all(8),
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          transitionBuilder: (child, animation) {
            return RotationTransition(
              turns: animation,
              child: ScaleTransition(scale: animation, child: child),
            );
          },
          child: Icon(
            isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            key: ValueKey(isDark),
            color: activeColor ?? (isDark ? Colors.amber : Theme.of(context).colorScheme.primary),
            size: 22,
          ),
        ),
        onPressed: () {
          ref.read(themeModeProvider.notifier).toggleTheme();
        },
      ),
    );
  }
}

/// Variante avec libellé texte ("Mode Clair" / "Mode Sombre")
class _LabeledThemeToggleButton extends ThemeToggleButton {
  const _LabeledThemeToggleButton({
    super.key,
    super.padding,
    super.activeColor,
  }) : super(showLabel: true);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return InkWell(
      onTap: () {
        ref.read(themeModeProvider.notifier).toggleTheme();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
              child: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                key: ValueKey(isDark),
                color: isDark ? Colors.amber : const Color(0xFF0F172A),
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              isDark ? "Mode Clair" : "Mode Sombre",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
