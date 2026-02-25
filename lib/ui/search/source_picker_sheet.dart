import 'package:flutter/material.dart';
import 'package:rhythmax/core/source/source_manager.dart';

class SourcePickerSheet extends StatelessWidget {
  const SourcePickerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final manager = SourceManager.instance;
    final activeId = manager.activeSource.id;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),

          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white30,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'Select source',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 16),

          ...manager.sources.map((source) {
            final isActive = source.id == activeId;

            return ListTile(
              leading: Image.asset(
                sourceIconFor(source.id),
                width: 28,
                height: 28,
              ),
              title: Text(
                source.name,
                style: TextStyle(
                  fontWeight:
                  isActive ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
              trailing: isActive
                  ? const Icon(
                Icons.check_circle,
                color: Colors.cyanAccent,
              )
                  : null,
              onTap: () {
                manager.setActiveSource(source.id);
                Navigator.pop(context);
              },
            );
          }).toList(),

          const SizedBox(height: 12),
        ],
      ),
    );
  }
  String sourceIconFor(String sourceId) {
    switch (sourceId) {
      case 'jiosaavn':
        return 'assets/images/jiosaavn.png';
      case 'tidal_binilossless':
        return 'assets/images/tidal.png';
      case 'youtube_music':
        return 'assets/images/youtube_music.png';
      default:
        return 'assets/images/album_placeholder.jpg';
    }
  }
}
