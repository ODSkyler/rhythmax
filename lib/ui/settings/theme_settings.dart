import 'package:flutter/material.dart';
import 'package:rhythmax/core/theme/theme_scope.dart';
import 'package:rhythmax/core/theme/app_theme_mode.dart';
import 'package:rhythmax/ui/app_shell_page.dart';

class ThemeSettingsPage extends StatelessWidget {
  const ThemeSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ThemeScope.of(context);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => AppShellPage.of(context).popPage(),
            ),
            title: const Text("Theme"),
            centerTitle: true,
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              _ThemeOptionTile(
                title: "Dark",
                subtitle: "Default dark theme",
                selected: controller.mode == AppThemeMode.dark,
                accentColor: controller.accentColor,
                onTap: () => controller.setTheme(AppThemeMode.dark),
              ),
              _ThemeOptionTile(
                title: "AMOLED",
                subtitle: "Pure black for AMOLED displays",
                selected: controller.mode == AppThemeMode.amoled,
                accentColor: controller.accentColor,
                onTap: () => controller.setTheme(AppThemeMode.amoled),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: SwitchListTile(
                  title: const Text("Dynamic Theme"),
                  subtitle: const Text("Extract accent color from artwork",
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'Poppins Medium',
                    color: Colors.white70
                    ),
                  ),
                  value: controller.dynamicThemeEnabled,
                  onChanged: (value) {
                    controller.toggleDynamicTheme(value);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                                OPTION TILE                                 */
/* -------------------------------------------------------------------------- */

class _ThemeOptionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final Color accentColor;
  final VoidCallback onTap;

  const _ThemeOptionTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      title: Text(
        title,
        style: theme.textTheme.titleMedium,
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'Poppins Medium',
          color: Colors.white70,
        ),
      ),
      trailing: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: selected
            ? Icon(
          Icons.check_circle,
          key: const ValueKey(true),
          color: accentColor,
        )
            : const Icon(
          Icons.circle_outlined,
          key: ValueKey(false),
        ),
      ),
      onTap: onTap,
    );
  }
}
