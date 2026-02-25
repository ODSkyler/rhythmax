import '../../models/home_section.dart';
import '../../models/home_item.dart';
import '../../models/album.dart';
import '../../models/playlist.dart';
import '../../utils/text_sanitizer.dart';

class JioSaavnHomeMapper {
  static List<HomeSection> map(Map<String, dynamic> json) {
    final sections = <HomeSection>[];

    _addSection(sections, 'Trending Now', json['new_trending']);
    _addSection(sections, 'Top Charts', json['charts']);
    _addSection(sections, 'Top Playlists', json['top_playlists']);
    _addSection(sections, 'New Releases', json['new_albums']);

    // Editorial / promo blocks
    json.forEach((key, value) {
      if (key.startsWith('promo:vx:data') && value is List) {
        _addSection(sections, 'Editorial Picks', value);
      }
    });

    return sections;
  }

  /* -------------------------------------------------------------------------- */

  static void _addSection(
      List<HomeSection> sections,
      String title,
      dynamic rawList,
      ) {
    if (rawList is! List || rawList.isEmpty) return;

    final items = <HomeItem>[];

    for (final raw in rawList) {
      if (raw is! Map) continue;

      final type = raw['type'];

      if (type == 'album') {
        items.add(
          HomeItem.album(
            Album(
              id: _token(raw['perma_url']),
              source: 'jiosaavn',
              title: cleanText(raw['title'] ?? ''),
              artists: [cleanText(raw['subtitle'] ?? '')],
              artworkUrl: _img(raw['image']),
              releaseDate: _year(raw['year']),
              tracks: const [],
            ),
          ),
        );
      }

      if (type == 'playlist') {
        items.add(
          HomeItem.playlist(
            Playlist(
              id: _token(raw['perma_url']),
              source: 'jiosaavn',
              type: PlaylistType.source,
              title: cleanText(raw['title'] ?? ''),
              description: cleanText(raw['subtitle'] ?? ''),
              artworkUrl: _img(raw['image']),
              tracks: const [],
            ),
          ),
        );
      }
    }

    if (items.isNotEmpty) {
      sections.add(HomeSection(title: title, items: items));
    }
  }

  /* -------------------------------------------------------------------------- */

  static String _token(dynamic url) =>
      url?.toString().split('/').last ?? '';

  static String? _img(dynamic url) =>
      url?.toString().replaceAll('150x150', '500x500');

  static DateTime? _year(dynamic y) {
    final v = int.tryParse(y?.toString() ?? '');
    return v != null ? DateTime(v) : null;
  }
}
