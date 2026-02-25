import 'track.dart';

class Album {
  final String id;
  final String source;
  final String title;
  final List<String> artists;
  final String? artworkUrl;
  final DateTime? releaseDate;
  final List<Track> tracks;
  final bool isExplicit;

  Album({
    required this.id,
    required this.source,
    required this.title,
    required this.artists,
    this.artworkUrl,
    this.releaseDate,
    required this.tracks,
    this.isExplicit = false,
  });
}
