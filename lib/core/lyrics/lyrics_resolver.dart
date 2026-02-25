import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/track.dart';
import 'lyrics_models.dart';
import 'lyrics_plus_parser.dart';
import 'lrclib_parser.dart';

class LyricsResolver {
  static const _lyricsPrimary =
      'https://lyrics-plus-backend.vercel.app/v2/lyrics/get';

  static const _lyricsBackup =
      'https://lyricsplus.prjktla.workers.dev/v2/lyrics/get';

  static const _searchEndpoint =
      'https://lyrics-plus-backend.vercel.app/v1/songlist/search';

  /* -------------------------------------------------- */
  /* PUBLIC ENTRY */
  /* -------------------------------------------------- */

  static Future<LyricsData?> resolve(
      Track track, {
        required void Function(String) onStatus,
      }) async {

    // 1️⃣ Apple / Musixmatch direct
    onStatus('Searching on Apple / Musixmatch...');

    final direct = await _fetchLyrics(
      title: track.title,
      artist: track.artists.join(' '),
      album: track.album ?? '',
      duration: track.duration.inSeconds,
    );
    if (direct != null) return direct;

    // 2️⃣ Normalized catalog search
    onStatus('Searching on Apple / Musixmatch...');

    final normalized = await _searchAndFetch(track);
    if (normalized != null) return normalized;

    // 3️⃣ LRCLIB fallback
    onStatus('Searching on LRCLIB...');

    final lrc = await _fetchLRCLib(track);
    if (lrc != null) return lrc;

    return null;
  }


  /* -------------------------------------------------- */
  /* LYRICS FETCH */
  /* -------------------------------------------------- */

  static Future<LyricsData?> _fetchLyrics({
    required String title,
    required String artist,
    required String album,
    required int duration,
  }) async {
    final params = {
      'title': title,
      'artist': artist,
      'album': album,
      'duration': duration.toString(),
      'source': 'apple,musixmatch-word,spotify,musixmatch',
    };

    for (final base in [_lyricsPrimary, _lyricsBackup]) {
      try {
        final uri = Uri.parse(base).replace(queryParameters: params);
        final res = await http.get(uri);
        if (res.statusCode != 200) continue;

        final json = jsonDecode(res.body);
        final parsed = LyricsPlusParser.parse(json);
        if (parsed != null) return parsed;
      } catch (_) {}
    }

    return null;
  }

  /* -------------------------------------------------- */
  /* NORMALIZED SEARCH */
  /* -------------------------------------------------- */

  static Future<LyricsData?> _searchAndFetch(Track track) async {
    try {
      final q = Uri.encodeComponent(
        '${track.title} ${track.artists.join(' ')}',
      );

      final uri = Uri.parse('$_searchEndpoint?q=$q');
      final res = await http.get(uri);

      if (res.statusCode != 200) return null;

      final List results = jsonDecode(res.body);
      if (results.isEmpty) return null;

      // pick best match (first result usually highest relevance)
      final best = results.first;

      return _fetchLyrics(
        title: best['title'] ?? track.title,
        artist: best['artist'] ?? track.artists.join(' '),
        album: best['album'] ?? '',
        duration: ((best['durationMs'] ?? 0) / 1000).round(),
      );
    } catch (_) {
      return null;
    }
  }

  /* -------------------------------------------------- */
  /* LRCLIB */
  /* -------------------------------------------------- */

  static Future<LyricsData?> _fetchLRCLib(Track track) async {
    try {
      final query = Uri.encodeComponent(
        '${track.title} ${track.artists.join(' ')}',
      );

      final uri =
      Uri.parse('https://lrclib.net/api/search?q=$query');

      final res = await http.get(uri);
      if (res.statusCode != 200) return null;

      final List results = jsonDecode(res.body);
      if (results.isEmpty) return null;

      final item = results.first;

      final synced = item['syncedLyrics'];
      if (synced == null || synced.toString().isEmpty) return null;

      return LRCLibParser.parse(synced);
    } catch (_) {
      return null;
    }
  }
}
