import 'package:flutter/material.dart';
import '../app_shell_page.dart';
import 'source_settings_page.dart';
import 'playback_settings_page.dart';
import 'theme_settings.dart';
import 'about_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Settings',
            style: TextStyle(
                fontSize: 32,
            )
          ),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.extension),
            title: const Text(
              'Source',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              AppShellPage.of(context).pushPage(
                const SourceSettingsPage(),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.play_circle_outline),
            title: const Text('Playback'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              AppShellPage.of(context).pushPage(
                const PlaybackSettingsPage()
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Theme'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              AppShellPage.of(context).pushPage(
                const ThemeSettingsPage()
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              AppShellPage.of(context).pushPage(
                const AboutPage()
              );
            },
          ),
        ],
      ),
    );
  }
}
