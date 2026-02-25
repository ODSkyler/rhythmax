class Artist {
  final String id;
  final String source;
  final String name;
  final String? artworkUrl;

  Artist({
    required this.id,
    required this.source,
    required this.name,
    this.artworkUrl,
  });
}
