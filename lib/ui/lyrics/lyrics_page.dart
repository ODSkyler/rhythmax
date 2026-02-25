import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:rhythmax/core/player/player_controller.dart';
import 'package:rhythmax/core/player/player_provider.dart';
import 'package:rhythmax/core/models/track.dart';
import 'package:rhythmax/core/lyrics/lyrics_resolver.dart';
import 'package:rhythmax/core/lyrics/lyrics_models.dart';

class LyricsPage extends StatefulWidget {
  final Track track; // kept (not used anymore, but untouched)

  const LyricsPage({super.key, required this.track});

  @override
  State<LyricsPage> createState() => _LyricsPageState();
}

class _LyricsPageState extends State<LyricsPage> {
  LyricsData? _lyrics;
  bool _loading = true;
  int _activeIndex = -1;
  late List<GlobalKey> _lineKeys;
  Track? _lastTrack;
  String _searchStatus = 'Searching for lyrics...';

  final ScrollController _scrollController = ScrollController();

  String? _prettySource() {
    if (_lyrics == null) return null;

    final raw = _lyrics!.source.toLowerCase();

    if (raw.contains('apple')) return 'Apple';
    if (raw.contains('musixmatch')) return 'Musixmatch';
    if (raw.contains('lrclib')) return 'LRCLIB';

    return null;
  }

  @override
  void initState() {
    super.initState();

    globalPlayer.addListener(_onPlayerTick);
    _reloadForTrack();

    _scrollController.addListener(() {
      if (!_scrollController.position.isScrollingNotifier.value) {
        // user released scroll → gently refocus active line
        if (_activeIndex != -1) {
          _scrollToActive();
        }
      }
    });
  }


  @override
  void dispose() {
    globalPlayer.removeListener(_onPlayerTick);
    _scrollController.dispose();
    super.dispose();
  }

  /* ---------------- TRACK CHANGE HANDLING ---------------- */

  void _reloadForTrack() {
    final track = globalPlayer.currentTrack;
    if (track == null) return;

    _lastTrack = track;
    _lyrics = null;
    _activeIndex = -1;
    _loading = true;

    _loadLyrics(track);
  }

  Future<void> _loadLyrics(Track track) async {
    setState(() {
      _loading = true;
      _searchStatus = 'Searching on Apple / Musixmatch...';
    });

    final lyrics = await LyricsResolver.resolve(
      track,
      onStatus: (s) {
        if (!mounted) return;
        setState(() => _searchStatus = s);
      },
    );

    if (!mounted) return;

    setState(() {
      _lyrics = lyrics;
      _loading = false;
      _lineKeys = List.generate(
        lyrics?.lines.length ?? 0,
            (_) => GlobalKey(),
      );
    });
  }


  /* ---------------- SYNC ---------------- */

  void _onPlayerTick() {
    final current = globalPlayer.currentTrack;

    // 🔁 detect track change (next / prev / repeat / auto)
    if (current != null && current != _lastTrack) {
      _reloadForTrack();
      setState(() {});
      return;
    }

    if (globalPlayer.isPlaying) {
      WakelockPlus.enable();
    } else {
      WakelockPlus.disable();
    }

    if (_lyrics == null) return;

    final pos = globalPlayer.position.inMilliseconds;

    // 🔁 repeat-one restart fix
    if (pos < 200 && _activeIndex > 0) {
      _activeIndex = -1;
    }

    final index = _lyrics!.lines.indexWhere(
          (l) =>
      pos >= l.start.inMilliseconds &&
          pos < l.end.inMilliseconds,
    );

    if (index != -1 && index != _activeIndex) {
      _activeIndex = index;
      _scrollToActive();
      setState(() {});
    }
  }

  void _scrollToActive() {
    if (_activeIndex < 0 || _activeIndex >= _lineKeys.length) return;

    final context = _lineKeys[_activeIndex].currentContext;
    if (context == null) return;

    Scrollable.ensureVisible(
      context,
      alignment: 0.5,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  /* ---------------- UI ---------------- */

  @override
  Widget build(BuildContext context) {
    final track = globalPlayer.currentTrack;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            if (track != null) _header(track),
            const Divider(height: 1, color: Colors.white12),
            Expanded(child: _lyricsBody()),
            _bottomBar(),
          ],
        ),
      ),
    );
  }

  /* ---------------- HEADER ---------------- */

  Widget _header(Track track) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 12, 12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: FadeInImage(
              placeholder:
              const AssetImage('assets/images/album_placeholder.jpg'),
              image: NetworkImage(track.artworkUrl ?? ''),
              width: 55,
              height: 55,
              fit: BoxFit.cover,
              imageErrorBuilder: (_, __, ___) {
                return Image.asset(
                  'assets/images/album_placeholder.jpg',
                  width: 55,
                  height: 55,
                  fit: BoxFit.cover,
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (track.isExplicit)
                      const Padding(
                        padding: EdgeInsets.only(right: 3),
                        child: Icon(
                          Icons.explicit,
                          size: 13,
                          color: Colors.grey,
                        ),
                      ),
                    Expanded(
                      child: Text(
                        track.artists.join(', '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Poppins Medium',
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  /* ---------------- LYRICS BODY ---------------- */

  Widget _lyricsBody() {
    if (_loading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const RefreshProgressIndicator(
              elevation: 0,
              valueColor: AlwaysStoppedAnimation(Colors.cyanAccent),
            ),
            const SizedBox(height: 16),
            Text(
              _searchStatus,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }


    if (_lyrics == null || _lyrics!.lines.isEmpty) {
      return const Center(
        child: Text(
          'Lyrics not found for this track',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: _lyrics!.lines.length + 1,
        itemBuilder: (_, i) {
          if (i == _lyrics!.lines.length) {
            final src = _lyrics!.source.toLowerCase();

            final showCredits =
                src.contains('apple') || src.contains('musixmatch');

            if (!showCredits || _lyrics!.songwriters.isEmpty) {
              return const SizedBox(height: 40);
            }

            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 30, 24, 20),
              child: Text(
                'Songwriters: ${_lyrics!.songwriters.join(', ')}',
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Poppins Medium',
                  fontSize: 13,
                  color: Colors.white54,
                  height: 1.4,
                ),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: Container(
              key: _lineKeys[i],
              child: LyricsLineWidget(
                line: _lyrics!.lines[i],
                active: i == _activeIndex,
              ),
            ),
          );
        }
    );
  }

  /* ---------------- BOTTOM BAR (UNCHANGED) ---------------- */

  Widget _bottomBar() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 50),
      child: Column(
        children: [
          /* ---------------- SLIDER ---------------- */

          Selector<PlayerController, Duration>(
            selector: (_, p) => p.position,
            builder: (_, position, __) {
              final player = context.read<PlayerController>();
              final duration = player.duration;
              final buffered =
                  player.bufferedPosition;

              return Slider(
                activeColor: Theme.of(context).colorScheme.primary,
                inactiveColor: Colors.white24,
                secondaryActiveColor: Colors.white38,
                value: position.inSeconds
                    .toDouble()
                    .clamp(0, duration.inSeconds.toDouble()),
                secondaryTrackValue:
                buffered.inSeconds
                    .toDouble()
                    .clamp(
                    0,
                    duration.inSeconds
                        .toDouble()),
                max: duration.inSeconds
                    .toDouble()
                    .clamp(1, double.infinity),
                onChanged: (v) =>
                    player.seek(Duration(seconds: v.toInt())),
              );
            },
          ),

          /* ---------------- TIME ROW ---------------- */

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
              children: [
                Selector<PlayerController, Duration>(
                  selector: (_, p) => p.position,
                  builder: (_, position, __) => Text(
                    _fmt(position),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),

                if (_lyrics != null)
                  Text(
                    'Source: ${_prettySource() ?? 'Unknown'}',
                    style: const TextStyle(
                      fontFamily: 'Poppins Medium',
                      fontSize: 12,
                      color: Colors.white54,
                      letterSpacing: 0.4,
                    ),
                  ),

                Selector<PlayerController, Duration>(
                  selector: (_, p) => p.duration,
                  builder: (_, duration, __) => Text(
                    _fmt(duration),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          /* ---------------- CONTROLS ---------------- */

          Row(
            mainAxisAlignment:
            MainAxisAlignment.spaceAround,
            children: [
              /* Shuffle */

              Selector<PlayerController, bool>(
                selector: (_, p) => p.shuffleEnabled,
                builder: (_, enabled, __) {
                  return IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      Icons.shuffle,
                      color: enabled
                          ? Colors.white
                          : Colors.white24,
                    ),
                    onPressed: context
                        .read<PlayerController>()
                        .toggleShuffle,
                  );
                },
              ),

              /* Previous */

              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                iconSize: 34,
                icon: const Icon(Icons.skip_previous),
                onPressed:
                context.read<PlayerController>().previous,
              ),

              /* Play / Pause + Loader */

              Selector<PlayerController, Map<String, dynamic>>(
                selector: (_, p) => {
                  'playing': p.isPlaying,
                  'loading': p.shouldShowLoader,
                },
                builder: (_, state, __) {
                  final playing =
                  state['playing'] as bool;
                  final showLoader =
                  state['loading'] as bool;

                  final player =
                  context.read<PlayerController>();

                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 65,
                        height: 65,
                        child: showLoader
                            ? const CircularProgressIndicator(
                          strokeWidth: 6,
                          valueColor:
                          AlwaysStoppedAnimation<
                              Color>(
                            Colors.grey,
                          ),
                        )
                            : const SizedBox(),
                      ),
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        child: IconButton(
                          icon: Icon(
                            playing
                                ? Icons.pause
                                : Icons.play_arrow,
                            color: Colors.black,
                            size: 40,
                          ),
                          onPressed: () {
                            playing
                                ? player.pause()
                                : player.play();
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),

              /* Next */

              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                iconSize: 34,
                icon: const Icon(Icons.skip_next),
                onPressed:
                context.read<PlayerController>().next,
              ),

              /* Repeat */

              Selector<PlayerController, RepeatMode>(
                selector: (_, p) => p.repeatMode,
                builder: (_, mode, __) {
                  return IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      mode == RepeatMode.one
                          ? Icons.repeat_one
                          : Icons.repeat,
                      color: mode != RepeatMode.off
                          ? Colors.white
                          : Colors.white24,
                    ),
                    onPressed: context
                        .read<PlayerController>()
                        .toggleRepeatMode,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }


  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

/* -------------------------------------------------------------------------- */
/*                             LINE WIDGET (UNCHANGED)                        */
/* -------------------------------------------------------------------------- */

class LyricsLineWidget extends StatelessWidget {
  final LyricsLine line;
  final bool active;

  const LyricsLineWidget({
    super.key,
    required this.line,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    if (line.words != null &&
        line.words!.isNotEmpty &&
        active) {
      return _wordSync();
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: active ? 1 : 0),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      builder: (_, t, __) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            line.text,
            textAlign: TextAlign.center,
            softWrap: true,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 22, // 🔒 fixed size = stable layout
              fontWeight: FontWeight.w700,
              color: Color.lerp(
                Colors.white38,
                Colors.white,
                t,
              ),
              shadows: active
                  ? [
                Shadow(
                  blurRadius: 0 * t,
                  color: Colors.cyanAccent.withOpacity(0.7),
                ),
              ]
                  : null,
            ),
          ),
        );
      },
    );
  }

  Widget _wordSync() {
    return AnimatedBuilder(
      animation: globalPlayer,
      builder: (_, __) {
        final now =
            globalPlayer.position.inMilliseconds;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: RichText(
            textAlign: TextAlign.center,
            softWrap: true,
            text: TextSpan(
              style: const TextStyle(fontFamily: 'Poppins'),
              children: _buildWords(now),
            ),
          ),
        );
      },
    );
  }

  List<InlineSpan> _buildWords(int now) {
    final spans = <InlineSpan>[];
    final words = line.words!;
    final fullText = line.text;

    int cursor = 0;

    for (int i = 0; i < words.length; i++) {
      final word = words[i];

      final start = word.time.inMilliseconds;
      final end = (i + 1 < words.length)
          ? words[i + 1].time.inMilliseconds
          : line.end.inMilliseconds;

      final progress =
      ((now - start) / (end - start)).clamp(0.0, 1.0);

      final eased =
      Curves.easeInOutCubic.transform(progress);

      final color = Color.lerp(
        Colors.white38,
        Colors.white,
        eased,
      )!;

      final wordText = word.text.trim();

      // find correct position inside original line text
      final index = fullText.indexOf(wordText, cursor);

      if (index != -1) {
        // add any missing text before word
        if (index > cursor) {
          spans.add(TextSpan(
            text: fullText.substring(cursor, index),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white54,
            ),
          ));
        }

        spans.add(TextSpan(
          text: wordText,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ));

        cursor = index + wordText.length;
      }
    }

    // add remaining text (if any)
    if (cursor < fullText.length) {
      spans.add(TextSpan(
        text: fullText.substring(cursor),
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: Colors.white54,
        ),
      ));
    }
    return spans;
  }
}


