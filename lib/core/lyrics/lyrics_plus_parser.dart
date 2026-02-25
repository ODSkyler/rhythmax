import 'lyrics_models.dart';

class LyricsPlusParser {
  static LyricsData? parse(Map<String, dynamic> json) {
    final type = json['type'];

    final LyricsType lyricsType =
    type == 'Word'
        ? LyricsType.wordSynced
        : type == 'Line'
        ? LyricsType.lineSynced
        : LyricsType.plain;

    final List rawLyrics = json['lyrics'] ?? [];
    if (rawLyrics.isEmpty) return null;

    final lines = <LyricsLine>[];

    for (final line in rawLyrics) {
      final int time = line['time'] ?? 0;
      final int duration = line['duration'] ?? 0;

      final text = (line['text'] ?? '').toString().trim();
      if (text.isEmpty) continue;

      List<LyricWord>? words;

      if (lyricsType == LyricsType.wordSynced) {
        final syllabus = line['syllabus'] as List? ?? [];
        final parsedWords = <LyricWord>[];

        for (final w in syllabus) {
          final wordText = (w['text'] ?? '').toString();
          if (wordText.trim().isEmpty) continue;

          final int wTime = w['time'] ?? time;

          parsedWords.add(
            LyricWord(
              text: wordText.trim(),
              time: Duration(milliseconds: wTime),
              isBackground:
              w['isBackground'] == true ||
                  wordText.startsWith('('),
            ),
          );
        }

        if (parsedWords.isNotEmpty) {
          words = parsedWords;
        }
      }

      lines.add(
        LyricsLine(
          start: Duration(milliseconds: time),
          end: Duration(milliseconds: time + duration),
          text: text,
          words: words,
        ),
      );
    }

    if (lines.isEmpty) return null;

    final writers =
        (json['metadata']?['songWriters'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
            [];

    return LyricsData(
      type: lyricsType,
      lines: lines,
      source:
      'lyrics-plus:${json['metadata']?['source']?.toString().toLowerCase() ?? 'unknown'}',
      songwriters: writers,
    );

  }
}
