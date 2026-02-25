import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/track.dart';

class CanonicalSong {
  final String title;
  final String artist;
  final String album;
  final Duration duration;

  CanonicalSong({
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
  });
}

class LyricsSongMatcher {
  static const _searchEndpoint =
      'https://lyrics-plus-backend.vercel.app/v1/songlist/search';

  /// Main entry
  static Future<CanonicalSong?> match(Track track) async {
    final query = _buildQuery(track.title, track.artists);

    try {
      final uri = Uri.parse(_searchEndpoint)
          .replace(queryParameters: {'q': query});

      final res = await http.get(uri);

      if (res.statusCode != 200) return null;

      final List results = jsonDecode(res.body);
      if (results.isEmpty) return null;

      return _pickBestMatch(results, track);
    } catch (_) {
      return null;
    }
  }

  /* ---------------- QUERY ---------------- */

  static String _buildQuery(String title, List<String> artists) {
    return '$title ${artists.join(' ')}';
  }

  /* ---------------- MATCH SCORING ---------------- */

  static CanonicalSong? _pickBestMatch(List raw, Track track) {
    final trackTitle = track.title.toLowerCase();
    final trackArtists = track.artists.join(' ').toLowerCase();
    final trackDuration = track.duration.inMilliseconds;

    double bestScore = -1;
    Map<String, dynamic>? best;

    for (final item in raw) {
      final String apiTitle = (item['title'] ?? '').toString().toLowerCase();
      final String apiArtist = (item['artist'] ?? '').toString().toLowerCase();

      final int apiDuration = item['durationMs'] ?? 0;

      if (apiDuration == 0) continue;

      double score = 0;

      // 🎯 Duration match (MOST IMPORTANT)
      final diff = (apiDuration - trackDuration).abs();

      if (diff < 1500) {
        score += 5;
      } else if (diff < 3000) {
        score += 3;
      } else if (diff < 6000) {
        score += 1;
      }

      // 🎵 Title similarity
      if (apiTitle.contains(trackTitle) ||
          trackTitle.contains(apiTitle)) {
        score += 3;
      }

      // 🎤 Artist similarity
      if (apiArtist.contains(trackArtists) ||
          trackArtists.contains(apiArtist)) {
        score += 2;
      }

      if (score > bestScore) {
        bestScore = score;
        best = item;
      }
    }

    if (best == null) return null;

    return CanonicalSong(
      title: best['title'] ?? '',
      artist: best['artist'] ?? '',
      album: best['album'] ?? '',
      duration: Duration(milliseconds: best['durationMs'] ?? 0),
    );
  }
}
