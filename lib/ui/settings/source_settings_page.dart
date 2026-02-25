import 'package:flutter/material.dart';
import '../../core/source/source_manager.dart';
import '../../core/source/music_source.dart';
import '../app_shell_page.dart';

class SourceSettingsPage extends StatefulWidget {
  const SourceSettingsPage({super.key});

  @override
  State<SourceSettingsPage> createState() => _SourceSettingsPageState();
}

class _SourceSettingsPageState extends State<SourceSettingsPage> {

  @override
  Widget build(BuildContext context) {
    final manager = SourceManager.instance;
    final active = manager.activeSource;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => AppShellPage.of(context).popPage(),
        ),
        title: const Text('Source'),
        centerTitle: true,
      ),
      body: ListView(
        children: manager.sources.map((source) {
          final isActive = source.id == active.id;

          return _sourceCard(
            source: source,
            isActive: isActive,
            onActivate: () async {
              if (!isActive) {
                await manager.setActiveSource(source.id);
                setState(() {});
              }
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _sourceCard({
    required MusicSource source,
    required bool isActive,
    required VoidCallback onActivate,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ?
                 Theme.of(context).colorScheme.primary
                 : Colors.transparent,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (source.settings?.buildLogo(context) != null) ...[
                    source.settings!.buildLogo(context)!,
                    const SizedBox(width: 8),
                  ],
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        source.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        source.tags,
                        style: TextStyle(
                          fontFamily: 'Poppins Medium',
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              TextButton(
                onPressed: isActive ? null : onActivate,
                child: Text(
                  isActive ? 'ACTIVE' : 'ACTIVATE',
                  style: TextStyle(
                    color: isActive
                        ? Theme.of(context).colorScheme.primary
                        : Colors.white,
                  ),
                ),
              ),
            ],
          ),

          // EXPANDED SETTINGS
          if (isActive && source.settings != null) ...[
            const Divider(),
            Builder(
              builder: (context) {
                return source.settings!.buildSettings(context);
              },
            ),
          ],
        ],
      ),
    );
  }
}
