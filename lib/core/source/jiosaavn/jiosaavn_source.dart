import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:rhythmax/core/models/home_section.dart';
import 'package:rhythmax/core/source/source_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../music_source.dart';
import '../../models/track.dart';
import '../../models/album.dart';
import '../../models/artist.dart';
import '../../models/artist_details.dart';
import '../../models/playlist.dart';

import 'jiosaavn_mapper.dart';
import 'jiosaavn_decrypt.dart';
import 'jiosaavn_quality.dart';
import 'jiosaavn_home_mapper.dart';
import 'jiosaavn_settings.dart';
import 'package:rhythmax/ui/settings/source_settings.dart';
import '../../player/player_provider.dart';

class JioSaavnSource extends MusicSource {
  @override
  String get id => 'jiosaavn';

  @override
  String get name => 'JioSaavn';

  @override
  String get tags => 'Official • Stable';

  static const String _baseUrl = 'https://www.jiosaavn.com/api.php';

  static const Map<String, String> _headers = {
    'User-Agent':
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Accept': '*/*',
    'Referer': 'https://www.jiosaavn.com/',
    'Origin': 'https://www.jiosaavn.com',
  };

  Map<String, String> get _headersWithLanguage {
    return {
      ..._headers,
      'cookie': _languageCookie,
    };
  }

  @override
  Future<Map<String, dynamic>?> prepareTrackForLibrary(Track track) async {
    final encrypted = _encryptedCache[track.id];

    if (encrypted == null) return null;

    return {
      'encrypted_media_url': encrypted,
    };
  }

  /* -------------------------------------------------------------------------- */
  /*                                  QUALITY                                   */
  /* -------------------------------------------------------------------------- */

  static const _prefQualityKey = 'jiosaavn_audio_quality';

  JioSaavnQuality _quality = JioSaavnQuality.normal;

  static const Map<JioSaavnQuality, String> _qualitySuffix = {
    JioSaavnQuality.low: '_48',
    JioSaavnQuality.normal: '_96',
    JioSaavnQuality.high: '_160',
    JioSaavnQuality.max: '_320',
  };

  static const Map<JioSaavnQuality, String> _qualityLabel = {
    JioSaavnQuality.low: 'Low',
    JioSaavnQuality.normal: 'Normal',
    JioSaavnQuality.high: 'High',
    JioSaavnQuality.max: 'MAX',
  };

  JioSaavnSource() {
    _restoreQuality();
    _restoreExplicit();
    _restoreLanguages();
  }

  Future<void> _restoreQuality() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_prefQualityKey);
    if (index != null && index < JioSaavnQuality.values.length) {
      _quality = JioSaavnQuality.values[index];
    }
  }

  Future<void> setQuality(JioSaavnQuality quality) async {
    _quality = quality;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefQualityKey, quality.index);
    globalPlayer.rebuildQueueWithNewQuality();
    SourceManager.instance.notifySourceUpdated();
  }

  JioSaavnQuality get selectedQuality => _quality;

  /* -------------------------------------------------------------------------- */
  /*                          LANGUAGE PREFERENCE                               */
  /* -------------------------------------------------------------------------- */

  static const _prefLangKey = 'jiosaavn_languages';

  // Defalut: English, Hindi
  Set<String> _languages = {'english', 'hindi'};

  Future<void> _restoreLanguages() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_prefLangKey);

    if (list != null && list.isNotEmpty) {
      _languages = list.toSet();
    }
  }

  Set<String> get selectedLanguages => Set.unmodifiable(_languages);

  Future<void> setLanguages(Set<String> langs) async {
    if (langs.isEmpty) return;

    _languages = langs;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefLangKey, _languages.toList());

    SourceManager.instance.notifySourceUpdated();

  }

  /* -------------------------------------------------------------------------- */
  /*                           EXPLICIT CONTENT                                 */
  /* -------------------------------------------------------------------------- */

  static const _prefExplicitKey = 'jiosaavn_explicit_enabled';

  bool _explicitEnabled = true;

  Future<void> _restoreExplicit() async {
    final prefs = await SharedPreferences.getInstance();
    _explicitEnabled = prefs.getBool(_prefExplicitKey) ?? true;
  }

  @override
  Future<void> setExplicitEnabled(bool enabled) async {
    _explicitEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefExplicitKey, enabled);

    SourceManager.instance.notifySourceUpdated();
  }

  @override
  bool get explicitEnabled => _explicitEnabled;


  /* -------------------------------------------------------------------------- */
  /*                                   CACHE                                    */
  /* -------------------------------------------------------------------------- */

  /// trackId → encrypted_media_url
  final Map<String, String> _encryptedCache = {};

  String? getCachedEncrypted(String trackId) {
    return _encryptedCache[trackId];
  }

  /* -------------------------------------------------------------------------- */
  /*                               TRACK SEARCH                                 */
  /* -------------------------------------------------------------------------- */

  @override
  SourceSettings get settings => JioSaavnSettings();


  @override
  Future<List<Track>> searchTracks(String query) async {
    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      '__call': 'search.getResults',
      'p': '1',
      'q': query,
      'n': '20',
      '_format': 'json',
      'ctx': 'web6dot0',
      'api_version': '4',
    });

    final res = await http.get(uri, headers: _headers);
    if (res.statusCode != 200) return [];

    final Map<String, dynamic> data = jsonDecode(res.body);
    final List results = data['results'] ?? [];

    final tracks = <Track>[];

    for (final item in results) {
      if (item is! Map || item['type'] != 'song') continue;

      final track =
      JioSaavnMapper.trackFromJson(Map<String, dynamic>.from(item));

      final encrypted = item['more_info']?['encrypted_media_url'];
      if (encrypted is String) {
        _encryptedCache[track.id] = encrypted;
      }

      tracks.add(track);
    }

    return tracks;
  }

  /* -------------------------------------------------------------------------- */
/*                               STREAM URL                                   */
/* -------------------------------------------------------------------------- */

  @override
  Future<Uri> getStreamUrl(
      Track track, {
        dynamic quality,
      }) async {

    /* ---------------- 1️⃣ LIBRARY (INSTANT PLAY) ---------------- */

    final fromLibrary = track.sourceExtras?['encrypted_media_url'];

    if (fromLibrary is String && fromLibrary.isNotEmpty) {
      final suffix = _qualitySuffix[_quality]!;
      final url = JioSaavnDecrypt.decrypt(fromLibrary, suffix);

      globalPlayer.setQualityLabel(_qualityLabel[_quality]!);
      return Uri.parse(url);
    }

    /* ---------------- 2️⃣ RUNTIME CACHE ---------------- */

    String? encrypted = _encryptedCache[track.id];

    /* ---------------- 3️⃣ FETCH IF NEEDED ---------------- */

    if (encrypted == null) {
      encrypted = await _fetchEncryptedUrl(track.id);

      if (encrypted == null) {
        throw Exception('Unable to fetch stream data for ${track.id}');
      }

      _encryptedCache[track.id] = encrypted;
    }

    /* ---------------- 4️⃣ DECRYPT ---------------- */

    final suffix = _qualitySuffix[_quality]!;
    final url = JioSaavnDecrypt.decrypt(encrypted, suffix);

    globalPlayer.setQualityLabel(_qualityLabel[_quality]!);

    return Uri.parse(url);
  }

  Future<String?> _fetchEncryptedUrl(String songId) async {
    try {
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        '__call': 'song.getDetails',
        'pids': songId,
        '_format': 'json',
        'api_version': '4',
        'ctx': 'web6dot0',
      });

      final res = await http.get(uri, headers: _headers);

      if (res.statusCode != 200) return null;

      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final song = json[songId] as Map<String, dynamic>?;

      final encrypted = song?['more_info']?['encrypted_media_url'];

      if (encrypted is String && encrypted.isNotEmpty) {
        return encrypted;
      }
    } catch (_) {}

    return null;
  }

  /* -------------------------------------------------------------------------- */
  /*                               ALBUM SEARCH                                 */
  /* -------------------------------------------------------------------------- */

  @override
  Future<List<Album>> searchAlbums(String query) async {
    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      '__call': 'search.getAlbumResults',
      'p': '1',
      'q': query,
      'n': '20',
      '_format': 'json',
      'ctx': 'web6dot0',
      'api_version': '4',
    });

    final res = await http.get(uri, headers: _headers);
    if (res.statusCode != 200) return [];

    final Map<String, dynamic> data = jsonDecode(res.body);
    final List results = data['results'] ?? [];

    final albums = <Album>[];

    for (final item in results) {
      if (item is! Map) continue;

      final permaUrl = item['perma_url']?.toString() ?? '';
      final token = _extractAlbumToken(permaUrl);

      if (token.isEmpty) continue;

      albums.add(
        Album(
          id: token,
          source: id,
          title: item['title']?.toString() ?? '',
          artists: [item['subtitle']?.toString() ?? ''],
          artworkUrl: item['image']?.toString(),
          releaseDate: _parseYear(item['year']),
          tracks: const [],
        ),
      );
    }

    return albums;
  }

  /* -------------------------------------------------------------------------- */
  /*                              ALBUM DETAILS                                 */
  /* -------------------------------------------------------------------------- */

  @override
  Future<Album> getAlbum(String albumToken) async {
    if (albumToken.isEmpty) {
      throw Exception('Album token is empty');
    }

    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      '__call': 'webapi.get',
      'token': albumToken,
      'type': 'album',
      'includeMetaTags': '0',
      '_format': 'json',
      'ctx': 'web6dot0',
      'api_version': '4',
    });

    final res = await http.get(uri, headers: _headers);
    if (res.statusCode != 200) {
      throw Exception('Failed to load album details');
    }

    final Map<String, dynamic> data = jsonDecode(res.body);

    if (data.containsKey('error')) {
      throw Exception('JioSaavn album error response');
    }

    final album =
    JioSaavnMapper.albumFromDetails(Map<String, dynamic>.from(data));

    // cache encrypted URLs
    final List list = data['list'] ?? [];
    for (final item in list) {
      if (item is! Map || item['type'] != 'song') continue;

      final id = item['id']?.toString();
      final encrypted = item['more_info']?['encrypted_media_url'];

      if (id != null && encrypted is String) {
        _encryptedCache[id] = encrypted;
      }
    }

    return album;
  }

  /* -------------------------------------------------------------------------- */
  /*                              ARTIST SEARCH                                 */
  /* -------------------------------------------------------------------------- */

  @override
  Future<List<Artist>> searchArtists(String query) async {
    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      'p': '1',
      'q': query,
      '_format': 'json',
      '_marker': '0',
      'api_version': '4',
      'ctx': 'web6dot0',
      'n': '20',
      '__call': 'search.getArtistResults',
    });

    final res = await http.get(uri, headers: _headers);
    if (res.statusCode != 200) return [];

    final data = jsonDecode(res.body);
    final results = data['results'] as List? ?? [];

    return results
        .where((item) =>
    item is Map &&
        item['type'] == 'artist' &&
        item['entity'] == 1)
        .map((item) => JioSaavnMapper.artistFromSearch(
      Map<String, dynamic>.from(item),
    ))
        .toList();
  }

  /* -------------------------------------------------------------------------- */
  /*                              PLAYLIST SEARCH                               */
  /* -------------------------------------------------------------------------- */

  @override
  Future<List<Playlist>> searchPlaylists(String query) async {
    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      'p': '1',
      'q': query,
      '_format': 'json',
      '_marker': '0',
      'api_version': '4',
      'ctx': 'web6dot0',
      'n': '20',
      '__call': 'search.getPlaylistResults',
    });

    final res = await http.get(uri, headers: _headers);
    if (res.statusCode != 200) return [];

    final data = jsonDecode(res.body);
    final results = data['results'] as List? ?? [];

    return results
        .where((e) => e['type'] == 'playlist')
        .map((e) => JioSaavnMapper.playlistFromSearch(
      Map<String, dynamic>.from(e),
    ))
        .toList();
  }

  /* -------------------------------------------------------------------------- */
  /*                              ARTIST DETAILS                                */
  /* -------------------------------------------------------------------------- */

  @override
  Future<Artist> getArtist(String artistToken) async {
    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      '__call': 'webapi.get',
      'token': artistToken,
      'type': 'artist',
      'ctx': 'web6dot0',
      'api_version': '4',
      '_format': 'json',
    });

    final res = await http.get(uri, headers: _headers);
    if (res.statusCode != 200) {
      throw Exception('Failed to load artist');
    }

    final json = jsonDecode(res.body);

    return Artist(
      id: artistToken,
      source: 'jiosaavn',
      name: json['name'] ?? '',
      artworkUrl: json['image']
          ?.toString()
          .replaceAll('150x150', '500x500'),
    );
  }
  @override
  Future<ArtistDetails> getArtistDetails(
      String artistToken, {
      int page = 0,
    }) async {
    // ---------- POPULAR (songs) ----------
    final popularUri = Uri.parse(_baseUrl).replace(queryParameters: {
      '__call': 'webapi.get',
      'token': artistToken,
      'type': 'artist',
      'p': page.toString(),
      'n_song': '50',
      'n_album': '0',
      'ctx': 'web6dot0',
      'api_version': '4',
      '_format': 'json',
      '_marker': '0',
    });

    // ---------- LATEST (Albums + Singles) ----------
    final latestUri = Uri.parse(_baseUrl).replace(queryParameters: {
      '__call': 'webapi.get',
      'token': artistToken,
      'type': 'artist',
      'p': page.toString(),
      'n_song': '0',
      'n_album': '50',
      'category': 'latest',
      'sort_order': 'desc',
      'ctx': 'web6dot0',
      'api_version': '4',
      '_format': 'json',
      '_marker': '0',
    });

    final popularRes = await http.get(popularUri, headers: _headers);
    final latestRes = await http.get(latestUri, headers: _headers);

    if (popularRes.statusCode != 200 || latestRes.statusCode != 200) {
      throw Exception('Failed to load artist details');
    }

    final popularJson = jsonDecode(popularRes.body);
    final latestJson = jsonDecode(latestRes.body);

    /* ---------------- SONGS ---------------- */

    final topTracks = (popularJson['topSongs'] as List? ?? [])
        .where((e) => e is Map && e['type'] == 'song')
        .map((e) => JioSaavnMapper.artistSongFromDetails(
      Map<String, dynamic>.from(e),
    ))
        .toList();

    /* ---------------- ALBUMS + SINGLES ---------------- */

    final albums = <Album>[];
    final singles = <Album>[];

    for (final raw in [
      ...(latestJson['topAlbums'] as List? ?? []),
      ...(latestJson['singles'] as List? ?? []),
    ]) {
      if (raw is! Map || raw['type'] != 'album') continue;

      final album = JioSaavnMapper.artistAlbumFromDetails(
        Map<String, dynamic>.from(raw),
      );

      // crude but reliable separation
      if ((raw['more_info']?['song_count'] ?? '0') == '1') {
        singles.add(album);
      } else {
        albums.add(album);
      }
    }

    /* ---------------- CACHE ENCRYPTED URLS ---------------- */

    for (final raw in popularJson['topSongs'] as List? ?? []) {
      if (raw is Map &&
          raw['type'] == 'song' &&
          raw['more_info']?['encrypted_media_url'] is String) {
        _encryptedCache[raw['id'].toString()] =
        raw['more_info']['encrypted_media_url'];
      }
    }

    /* ---------------- RETURN ---------------- */

    return ArtistDetails(
      artist: Artist(
        id: artistToken,
        source: 'jiosaavn',
        name: popularJson['name'] ?? '',
        artworkUrl: popularJson['image']
            ?.toString()
            .replaceAll('150x150', '500x500'),
      ),
      topTracks: topTracks,
      albums: albums,
      singles: singles,
    );
  }

  /* -------------------------------------------------------------------------- */
  /*                       ARTIST ALBUMS / SINGLES PAGED                        */
  /* -------------------------------------------------------------------------- */

  Future<List<Album>> getArtistAlbumsPaged({
    required String artistToken,
    required int page,
  }) async {
    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      '__call': 'webapi.get',
      'token': artistToken,
      'type': 'artist',
      'p': page.toString(),        // ✅ pagination
      'n_song': '0',
      'n_album': '50',
      'category': 'latest',
      'sort_order': 'desc',
      'ctx': 'web6dot0',
      'api_version': '4',
      '_format': 'json',
      '_marker': '0',
    });

    final res = await http.get(uri, headers: _headers);
    if (res.statusCode != 200) {
      throw Exception('Failed to load artist albums (page $page)');
    }

    final json = jsonDecode(res.body);

    final albums = <Album>[];

    for (final raw in [
      ...(json['topAlbums'] as List? ?? []),
      ...(json['singles'] as List? ?? []),
    ]) {
      if (raw is! Map || raw['type'] != 'album') continue;

      albums.add(
        JioSaavnMapper.albumFromSearch(
          Map<String, dynamic>.from(raw),
        ),
      );
    }

    return albums;
  }

  /* -------------------------------------------------------------------------- */
  /*                              PLAYLIST DETAILS                              */
  /* -------------------------------------------------------------------------- */

  @override
  Future<Playlist> getPlaylist(String playlistToken) async {
    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      '__call': 'webapi.get',
      'token': playlistToken,      // 🔑 TOKEN, NOT ID
      'type': 'playlist',
      'p': '1',
      'n': '50',
      'includeMetaTags': '0',
      'ctx': 'web6dot0',
      'api_version': '4',
      '_format': 'json',
      '_marker': '0',
    });

    final res = await http.get(uri, headers: _headers);
    if (res.statusCode != 200) {
      throw Exception('Failed to load playlist');
    }

    final data = jsonDecode(res.body);

    final playlist = JioSaavnMapper.playlistFromDetails(
      Map<String, dynamic>.from(data),
    );

    // 🔐 cache encrypted_media_url (same system as album)
    final list = data['list'] as List? ?? [];
    for (final item in list) {
      if (item is Map && item['type'] == 'song') {
        final id = item['id']?.toString();
        final encrypted = item['more_info']?['encrypted_media_url'];
        if (id != null && encrypted is String) {
          _encryptedCache[id] = encrypted;
        }
      }
    }
    return playlist;
  }

/* -------------------------------------------------------------------------- */
/*                                HOME FEED                                   */
/* -------------------------------------------------------------------------- */

  String get _languageCookie {

    final langs = selectedLanguages.join(',');


    final defaultLang =
        selectedLanguages.isNotEmpty ? selectedLanguages.first : 'english';

    return 'DL=$defaultLang; L=$langs';
  }

  @override
  Future<List<HomeSection>> getHomeFeed() async {
    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      '__call': 'webapi.getLaunchData',
      'api_version': '4',
      '_format': 'json',
      '_marker': '0',
      'ctx': 'web6dot0',
    });

    final res = await http.get(uri, headers: _headersWithLanguage);
    if (res.statusCode != 200) {
      throw Exception('Failed to load JioSaavn home feed');
    }

    final Map<String, dynamic> json = jsonDecode(res.body);

    return JioSaavnHomeMapper.map(json);
  }
  String get debugLanguageString => _languages.join(',');


  /* -------------------------------------------------------------------------- */
  /*                                  HELPERS                                   */
  /* -------------------------------------------------------------------------- */

  String _extractAlbumToken(String url) {
    final parts = url.split('/');
    return parts.isNotEmpty ? parts.last : '';
  }

  DateTime? _parseYear(dynamic year) {
    final y = int.tryParse(year?.toString() ?? '');
    return y != null ? DateTime(y) : null;
  }
}
