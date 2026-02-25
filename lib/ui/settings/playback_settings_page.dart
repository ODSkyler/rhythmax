import 'package:flutter/material.dart';
import 'package:rhythmax/core/player/player_provider.dart';
import '../app_shell_page.dart';

class PlaybackSettingsPage extends StatelessWidget {
  const PlaybackSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => AppShellPage.of(context).popPage(),
        ),
        title: const Text('Playback'),
        centerTitle: true,
      ),

      body: AnimatedBuilder(
        animation: globalPlayer,
        builder: (_, __) {
          return ListView(
            children: [
              _section('Audio'),

              SwitchListTile(
                secondary: const Icon(Icons.all_inclusive),
                title: const Text('Gapless Playback'),
                subtitle: const Text(
                  'Play songs without silence between tracks',
                  style: TextStyle(
                    fontFamily: 'Poppins Medium',
                    color: Colors.grey,
                  ),
                ),
                value: globalPlayer.gaplessEnabled,
                onChanged: globalPlayer.toggleGapless,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.white54,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
