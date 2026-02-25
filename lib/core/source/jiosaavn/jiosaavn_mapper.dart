import '../../models/track.dart';
import '../../models/album.dart';
import '../../models/artist.dart';
import '../../models/playlist.dart';
import '../../utils/text_sanitizer.dart';

class JioSaavnMapper {
  /* -------------------------------------------------------------------------- */
  /*                                   TRACK                                    */
  /* -------------------------------------------------------------------------- */

  static Track trackFromJson(Map<String, dynamic> json) {
    final more = json['more_info'] ?? {};
    final artistMap = more['artistMap'] ?? {};

    // 🎤 Primary artists
    final primaryArtists =
    (artistMap['primary_artists'] as List? ?? []);

    // ✨ Featured artists
    final featuredArtists =
    (artistMap['featured_artists'] as List? ?? []);

    final allArtistObjs = [
      ...primaryArtists,
      ...featuredArtists,
    ];

    final artistNames = <String>[];
    final artistIds = <String>[];

    for (final a in allArtistObjs) {
      final name = cleanText(a['name']?.toString() ?? '');
      final perma = a['perma_url']?.toString();

      if (name.isNotEmpty) artistNames.add(name);

      if (perma != null && perma.isNotEmpty) {
        artistIds.add(perma.split('/').last);
      }
    }

    // 🧾 Album token
    String? albumId;
    final albumUrl = more['album_url'];
    if (albumUrl != null) {
      albumId = albumUrl.toString().split('/').last;
    }

    return Track(
      id: json['id']?.toString() ?? '',
      source: 'jiosaavn',
      sourceUrl: json['perma_url'],
      sourceExtras: {
        'encrypted_media_url': more['encrypted_media_url']
      },
      title: cleanText(json['title'] ?? ''),
      artists: artistNames.isNotEmpty
          ? artistNames
          : [cleanText(json['subtitle'] ?? '')],
      artistIds: artistIds,
      album: cleanText(more['album'] ?? ''),
      albumId: albumId,
      artworkUrl: _upgradeImage(json['image']),
      duration: Duration(
        seconds: int.tryParse(more['duration']?.toString() ?? '0') ?? 0,
      ),
      isExplicit: json['explicit_content'] == '1',
    );
  }


  /* -------------------------------------------------------------------------- */
  /*                                ALBUM SEARCH                                */
  /* -------------------------------------------------------------------------- */

  static Album albumFromSearch(Map<String, dynamic> json) {
    final token = _extractAlbumToken(json['perma_url']);

    return Album(
      id: token, // ✅ THIS IS THE REAL ALBUM ID
      source: 'jiosaavn',
      title: cleanText(json['title'] ?? ''),
      artists: [cleanText(json['subtitle'] ?? '')],
      artworkUrl: _upgradeImage(json['image']),
      releaseDate: _parseYear(json['year']),
      tracks: const [],
    );
  }

  /* -------------------------------------------------------------------------- */
  /*                               ALBUM DETAILS                                */
  /* -------------------------------------------------------------------------- */

  static Album albumFromDetails(Map<String, dynamic> json) {
    // 🚨 HARD GUARD — JioSaavn often returns error payloads
    if (json.containsKey('error')) {
      throw Exception('JioSaavn album error response');
    }

    final tracksJson = json['list'];
    if (tracksJson is! List) {
      throw Exception('Invalid album payload (no track list)');
    }

    final artistMap =
        json['more_info']?['artistMap'] ?? json['artistMap'] ?? {};

    final primaryArtists =
    (artistMap['primary_artists'] as List? ?? [])
        .map((a) => cleanText(a['name']?.toString() ?? ''))
        .where((n) => n.isNotEmpty)
        .toList();

    final tracks = <Track>[];
    for (final item in tracksJson) {
      if (item is Map<String, dynamic> && item['type'] == 'song') {
        tracks.add(trackFromJson(item));
      }
    }

    return Album(
      id: _extractAlbumToken(json['perma_url']) ??
          json['id']?.toString() ??
          '',
      source: 'jiosaavn',
      title: cleanText(json['title'] ?? ''),
      artists: primaryArtists,
      artworkUrl: _upgradeImage(json['image']),
      releaseDate: _parseReleaseDate(json),
      tracks: tracks,
    );
  }

  /* -------------------------------------------------------------------------- */
  /*                             ARTIST SEARCH                                  */
  /* -------------------------------------------------------------------------- */

  static Artist artistFromSearch(Map<String, dynamic> json) {
    final permaUrl = json['perma_url']?.toString() ?? '';
    final token = permaUrl.split('/').last; // 🔑 THIS IS THE KEY

    return Artist(
      id: token, // ✅ USE TOKEN, NOT NUMERIC ID
      source: 'jiosaavn',
      name: cleanText(json['name'] ?? ''),
      artworkUrl: _upgradeArtistImage(json['image']),
    );
  }

  /* -------------------------------------------------------------------------- */
  /*                            ARTIST DETAILS                                  */
  /* -------------------------------------------------------------------------- */

  static Track artistSongFromDetails(Map<String, dynamic> json) {
    return trackFromJson(json);
  }

  static Album artistAlbumFromDetails(Map<String, dynamic> json) {
    final token = _extractAlbumToken(json['perma_url']);

    return Album(
      id: token,
      source: 'jiosaavn',
      title: cleanText(json['title'] ?? ''),
      artists: [cleanText(json['subtitle'] ?? '')],
      artworkUrl: _upgradeImage(json['image']),
      releaseDate: _parseYear(json['year']),
      tracks: const [], // loaded when album page opens
    );
  }


  /* -------------------------------------------------------------------------- */
  /*                            PLAYLIST SEARCH                                 */
  /* -------------------------------------------------------------------------- */

  static Playlist playlistFromSearch(Map<String, dynamic> json) {
    final permaUrl = json['perma_url']?.toString() ?? '';
    final token = permaUrl.split('/').last; // ✅ REQUIRED

    return Playlist(
      id: token,
      source: 'jiosaavn',
      type: PlaylistType.source,
      title: cleanText(json['title'] ?? ''),
      description: cleanText(json['subtitle'] ?? ''),
      artworkUrl: (json['image'] as String?)
          ?.replaceAll('150x150', '500x500'),
      tracks: const [],           // loaded later
      isEditable: false,
    );
  }

  /* -------------------------------------------------------------------------- */
  /*                              PLAYLIST DETAILS                              */
  /* -------------------------------------------------------------------------- */

  static Playlist playlistFromDetails(Map<String, dynamic> json) {
    final list = json['list'] as List? ?? [];
    final tracks = <Track>[];

    for (final item in list) {
      if (item is Map && item['type'] == 'song') {
        tracks.add(
          trackFromJson(
            Map<String, dynamic>.from(item),
          ),
        );
      }
    }

    final permaUrl = json['perma_url']?.toString() ?? '';
    final token = permaUrl.split('/').last;

    return Playlist(
      id: token,
      source: 'jiosaavn',
      type: PlaylistType.source,
      title: cleanText(json['title'] ?? ''),
      description: cleanText(json['header_desc'] ?? ''),
      artworkUrl: json['image']?.toString(),
      tracks: tracks,
      isEditable: false,
    );
  }

  /* -------------------------------------------------------------------------- */
  /*                                  HELPERS                                   */
  /* -------------------------------------------------------------------------- */

  static String? _upgradeImage(dynamic url) {
    if (url == null) return null;
    return url.toString().replaceAll('150x150', '500x500');
  }

  static String? _upgradeArtistImage(dynamic url) {
    if (url == null) return null;

    final u = url.toString();

    // Artist images usually come as 50x50
    return u
        .replaceAll('50x50', '500x500')
        .replaceAll('150x150', '500x500');
  }

  static DateTime? _parseYear(dynamic year) {
    if (year == null) return null;
    final y = int.tryParse(year.toString());
    if (y == null) return null;
    return DateTime(y);
  }

  static DateTime? _parseReleaseDate(Map<String, dynamic> json) {
    final release = json['release_date'];
    if (release != null) {
      return DateTime.tryParse(release.toString());
    }
    return _parseYear(json['year']);
  }

  /// 🔑 CRITICAL FIX
  /// Extracts `kG1RAAq0CUA_` from:
  /// https://www.jiosaavn.com/album/kiss-land/kG1RAAq0CUA_
  static String _extractAlbumToken(dynamic permaUrl) {
    if (permaUrl == null) return '';
    final parts = permaUrl.toString().split('/');
    return parts.isNotEmpty ? parts.last : '';
  }
}
