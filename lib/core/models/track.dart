enum AudioQuality {
  low,
  medium,
  high,
  lossless,
  hiRes,
}

class Track {
  final String id;
  final String source;

  final String title;

  final List<String> artists;
  final List<String> artistIds;

  final String? album;
  final String? albumId;

  final Duration duration;

  final String? artworkUrl;

  final bool isExplicit;

  /// Optional source-specific URL (not required for all sources)
  final String? sourceUrl;

  /// ⭐ Source-specific playback metadata
  /// Example (JioSaavn):
  /// { "encrypted_media_url": "..." }
  final Map<String, dynamic>? sourceExtras;

  const Track({
    required this.id,
    required this.source,
    required this.title,
    required this.artists,
    required this.artistIds,
    this.album,
    this.albumId,
    required this.duration,
    this.artworkUrl,
    this.isExplicit = false,
    this.sourceUrl,
    this.sourceExtras, // ⭐ NEW
  });

  // ✅ COPY WITH (VERY IMPORTANT FOR LIKE SYSTEM)
  Track copyWith({
    String? id,
    String? source,
    String? title,
    List<String>? artists,
    List<String>? artistIds,
    String? album,
    String? albumId,
    Duration? duration,
    String? artworkUrl,
    bool? isExplicit,
    String? sourceUrl,
    Map<String, dynamic>? sourceExtras,
  }) {
    return Track(
      id: id ?? this.id,
      source: source ?? this.source,
      title: title ?? this.title,
      artists: artists ?? this.artists,
      artistIds: artistIds ?? this.artistIds,
      album: album ?? this.album,
      albumId: albumId ?? this.albumId,
      duration: duration ?? this.duration,
      artworkUrl: artworkUrl ?? this.artworkUrl,
      isExplicit: isExplicit ?? this.isExplicit,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      sourceExtras: sourceExtras ?? this.sourceExtras,
    );
  }
}