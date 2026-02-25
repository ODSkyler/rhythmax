import 'track.dart';

enum PlaylistType {
  source,   // From YouTube Music, JioSaavn, etc.
  user,     // Created by user inside Rhythmax
}

class Playlist {
  final String id;

  /// source id OR 'local'
  final String source;
  final PlaylistType type;
  final String title;
  final String? description;
  final String? artworkUrl;
  final List<Track> tracks;
  final bool isEditable;

  Playlist({
    required this.id,
    required this.source,
    required this.type,
    required this.title,
    this.description,
    this.artworkUrl,
    required this.tracks,
    this.isEditable = false,
  });
}
