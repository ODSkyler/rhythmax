enum LyricsType {
  plain,
  lineSynced,
  wordSynced,
}

class LyricWord {
  final String text;
  final Duration time;
  final bool isBackground;

  LyricWord({
    required this.text,
    required this.time,
    this.isBackground = false,
  });
}

class LyricsLine {
  final Duration start;
  final Duration end;
  final String text;
  final List<LyricWord>? words;

  LyricsLine({
    required this.start,
    required this.end,
    required this.text,
    this.words,
  });
}

class LyricsData {
  final LyricsType type;
  final List<LyricsLine> lines;
  final String source;
  final List<String> songwriters;

  LyricsData({
    required this.type,
    required this.lines,
    required this.source,
    this.songwriters = const [],
  });
}
