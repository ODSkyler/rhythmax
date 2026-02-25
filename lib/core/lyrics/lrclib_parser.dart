import 'lyrics_models.dart';

class LRCLibParser {
  static LyricsData? parse(String lrc) {
    final lines = <LyricsLine>[];

    // Supports:
    // [mm:ss.xx]
    // [mm:ss.xxx]
    final regex = RegExp(r'\[(\d+):(\d+(?:\.\d+)?)\](.*)');

    for (final raw in lrc.split('\n')) {
      final match = regex.firstMatch(raw);
      if (match == null) continue;

      final minutes = int.parse(match.group(1)!);
      final seconds = double.parse(match.group(2)!);

      final startMs = ((minutes * 60) + seconds) * 1000;

      final text = match.group(3)!.trim();
      if (text.isEmpty) continue;

      lines.add(
        LyricsLine(
          start: Duration(milliseconds: startMs.round()),
          end: Duration.zero, // will be fixed later
          text: text,
        ),
      );
    }

    if (lines.isEmpty) return null;

    // 🎯 Fix end times based on next line (real lyric timing)
    for (int i = 0; i < lines.length; i++) {
      final current = lines[i];

      final end = (i + 1 < lines.length)
          ? lines[i + 1].start
          : current.start + const Duration(seconds: 4);

      lines[i] = LyricsLine(
        start: current.start,
        end: end,
        text: current.text,
        words: current.words,
      );
    }

    return LyricsData(
      type: LyricsType.lineSynced,
      lines: lines,
      source: 'lrclib',
    );
  }
}
