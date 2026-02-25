import 'package:flutter/material.dart';
import 'package:rhythmax/core/source/jiosaavn/jiosaavn_source.dart';
import 'package:rhythmax/core/source/jiosaavn/jiosaavn_quality.dart';
import 'package:rhythmax/ui/settings/source_settings.dart';
import 'package:rhythmax/core/source/source_manager.dart';

class JioSaavnSettings extends SourceSettings {
  @override
  String get title => 'JioSaavn Settings';

  @override
  Widget buildLogo(BuildContext context) {
    return Image.asset(
      'assets/images/jiosaavn.png',
      height: 45,
      width: 45,
    );
  }

  /* -------------------------------------------------------------------------- */
  /*                               AUDIO QUALITY                                */
  /* -------------------------------------------------------------------------- */

  static const Map<JioSaavnQuality, String> _qualityLabels = {
    JioSaavnQuality.low: 'Low • 48 kbps (AAC)',
    JioSaavnQuality.normal: 'Normal • 96 kbps (AAC)',
    JioSaavnQuality.high: 'High • 160 kbps (AAC)',
    JioSaavnQuality.max: 'MAX • 320 kbps (AAC)',
  };

  /* -------------------------------------------------------------------------- */
  /*                              MUSIC LANGUAGES                               */
  /* -------------------------------------------------------------------------- */

  static const Map<String, String> _languages = {
    'english': 'English',
    'hindi': 'Hindi',
    'punjabi': 'Punjabi',
    'tamil': 'Tamil',
    'telugu': 'Telugu',
    'marathi': 'Marathi',
    'gujarati': 'Gujarati',
    'bengali': 'Bengali',
    'kannada': 'Kannada',
    'bhojpuri': 'Bhojpuri',
    'malayalam': 'Malayalam',
    'sanskrit': 'Sanskrit',
    'haryanvi': 'Haryanvi',
    'rajasthani': 'Rajasthani',
    'odia': 'Odia',
    'assamese': 'Assamese',
  };

  /* -------------------------------------------------------------------------- */
  /*                                   UI                                       */
  /* -------------------------------------------------------------------------- */

  @override
  Widget buildSettings(BuildContext context) {
    return AnimatedBuilder(
      animation: SourceManager.instance,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _tile(
              icon: Icons.language,
              title: 'Music Languages',
              subtitle: _languageLabel(context),
              onTap: () => _showLanguageDialog(context),
            ),

            _tile(
              icon: Icons.multitrack_audio,
              title: 'Audio Quality',
              subtitle: _qualityLabel(context),
              onTap: () => _showQualityDialog(context),
            ),

            _explicitToggle(context),

            _tile(
              icon: Icons.info_outline,
              title: 'Source Info',
              subtitle: 'About JioSaavn',
              onTap: () {
                _info(
                  context,
                  'JioSaavn is an Indian music streaming platform offering a wide '
                      'catalog of Hindi, English, and regional music.\n\n'
                      'About content metadata:\n'
                      'Explicit content on JioSaavn is marked at the album level. '
                      'If any track in an album is explicit, all tracks in that album '
                      'may appear as explicit, even if individual tracks are clean.\n\n'
                      'Rhythmax connects to publicly available JioSaavn APIs for music '
                      'streaming and discovery. This is an unofficial integration and '
                      'is not affiliated with or endorsed by JioSaavn.\n\n'
                      'Rhythmax does not host, store, or distribute any music files. '
                      'All content is streamed directly from the selected source.',
                );
              },
            ),
          ],
        );
      },
    );
  }


  /* -------------------------------------------------------------------------- */
  /*                              LANGUAGE DIALOG                               */
  /* -------------------------------------------------------------------------- */

  void _showLanguageDialog(BuildContext context) {
    final source = _source(context);
    if (source == null) return;

    final selected = Set<String>.from(source.selectedLanguages);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Select Languages'),
              content: SingleChildScrollView(
                child: Column(
                  children: _languages.entries.map((entry) {
                    return CheckboxListTile(
                      value: selected.contains(entry.key),
                      title: Text(entry.value),
                      onChanged: (checked) {
                        setState(() {
                          if (checked == true) {
                            selected.add(entry.key);
                          } else if (selected.length > 1) {
                            selected.remove(entry.key);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    await source.setLanguages(selected);
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }


  String _languageLabel(BuildContext context) {
    final source = _source(context);
    if (source == null) return '';

    final names = source.selectedLanguages
        .map((l) => _languages[l])
        .whereType<String>()
        .toList();

    if (names.isEmpty) return 'None';

    if (names.length <= 4) {
      return names.join(', ');
    }

    return '${names.take(4).join(', ')} +${names.length - 4}';
  }


  /* -------------------------------------------------------------------------- */
  /*                              EXPLICIT TOGGLE                               */
  /* -------------------------------------------------------------------------- */

  Widget _explicitToggle(BuildContext context) {
    final source = _source(context);
    if (source == null) return const SizedBox.shrink();

    return SwitchListTile(
      secondary: const Icon(Icons.explicit),
      title: const Text('Explicit Content'),
      subtitle: Text(source.explicitEnabled ? 'Enabled' : 'Disabled'),
      value: source.explicitEnabled,
      onChanged: (value) async {
        await source.setExplicitEnabled(value);

      },
    );
  }

  /* -------------------------------------------------------------------------- */
  /*                                   TILE                                     */
  /* -------------------------------------------------------------------------- */

  Widget _tile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      onTap: onTap,
    );
  }

  /* -------------------------------------------------------------------------- */
  /*                                 INFO DIALOG                                */
  /* -------------------------------------------------------------------------- */

  void _info(BuildContext context, String msg) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Info'),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }


  /* -------------------------------------------------------------------------- */
  /*                              QUALITY LABEL                                 */
  /* -------------------------------------------------------------------------- */

  String _qualityLabel(BuildContext context) {
    final source = _source(context);
    if (source == null) return '';
    return _qualityLabels[source.selectedQuality]!;
  }

  /* -------------------------------------------------------------------------- */
  /*                              QUALITY DIALOG                                */
  /* -------------------------------------------------------------------------- */

  void _showQualityDialog(BuildContext context) {
    final source = _source(context);
    if (source == null) return;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return SimpleDialog(
          title: const Text('Select Audio Quality'),
          children: JioSaavnQuality.values.map((q) {
            final isSelected = source.selectedQuality == q;

            return ListTile(
              title: Text(_qualityLabels[q]!),
              trailing: isSelected
                  ? const Icon(Icons.check, color: Colors.cyanAccent)
                  : null,
              onTap: () async {
                await source.setQuality(q);
                Navigator.pop(dialogContext);
              },
            );
          }).toList(),
        );
      },
    );
  }


  /* -------------------------------------------------------------------------- */
  /*                                SOURCE                                      */
  /* -------------------------------------------------------------------------- */

  JioSaavnSource? _source(BuildContext context) {
    final src = SourceManager.instance.activeSource;
    return src is JioSaavnSource ? src : null;
  }
}
