import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rhythmax/core/models/track.dart';
import 'package:rhythmax/core/player/player_provider.dart';
import 'package:rhythmax/ui/player/queue_bottom_sheet.dart';
import 'package:rhythmax/core/player/player_controller.dart';
import 'package:rhythmax/core/theme/theme_scope.dart';
import 'package:rhythmax/core/source/source_manager.dart';
import 'package:rhythmax/ui/lyrics/lyrics_page.dart';
import 'package:rhythmax/ui/widget/overflow_marquee_text.dart';
import 'package:rhythmax/ui/player/player_options_sheet.dart';
import 'package:rhythmax/ui/app_shell_page.dart';

class FullPlayerPage extends StatefulWidget {
  const FullPlayerPage({super.key});

  @override
  State<FullPlayerPage> createState() => _FullPlayerPageState();
}

class _FullPlayerPageState extends State<FullPlayerPage> {

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final dynamicEnabled = theme.dynamicThemeEnabled;
    final accent = colorScheme.primary;
    final baseBg = theme.backgroundColor;

    final track = context.select<PlayerController, Track?>(
          (p) => p.currentTrack,
    );

    if (track == null) {
      return SizedBox.expand(
        child: Container(
          color: theme.backgroundColor,
          child: const Center(child: Text('Nothing playing')),
        ),
      );
    }

    return SizedBox.expand(
      child: Container(
        decoration: BoxDecoration(
          gradient: dynamicEnabled
              ? LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              accent,
              baseBg,
            ],
          )
              : null,
          color: dynamicEnabled ? null : baseBg,
        ),
        child: SafeArea(
          child: Column(
            children: [
              /* ---------------- BODY ---------------- */

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        final shell = AppShellPage.of(context);
                        shell.popPage();
                      },
                    ),

                    AnimatedBuilder(
                      animation: globalPlayer,
                      builder: (_, __) {
                        final type = globalPlayer.playingFromType;
                        final title = globalPlayer.playingFromTitle;

                        if (type == null) return const SizedBox();

                        return Column(
                          children: [
                            Text(
                              'PLAYING FROM $type',
                              style: const TextStyle(
                                fontFamily: 'Poppins Medium',
                                fontSize: 11,
                                letterSpacing: 1.2,
                                color: Colors.white60,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (title != null)
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () {
                        final shell = AppShellPage.of(context);

                        showModalBottomSheet(
                          useSafeArea: true,
                          context: context,
                          backgroundColor: Colors.transparent,
                          isScrollControlled: true,
                          builder: (_) => PlayerOptionsSheet(
                            track: track,
                            shell: shell,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 23),
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black45,
                              blurRadius: 30,
                              offset: const Offset(0, 18),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: artworkImage(
                            track.artworkUrl,
                            size: double.infinity,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              /* ---------------- BOTTOM SECTION ---------------- */

              Container(
                color: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding:
                        const EdgeInsets.symmetric(horizontal: 10),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              OverflowMarqueeText(
                                text: track.title,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  if (track.isExplicit)
                                    const Padding(
                                      padding:
                                      EdgeInsets.only(right: 3),
                                      child: Icon(
                                        Icons.explicit,
                                        size: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  Expanded(
                                    child: Text(
                                      track.artists.join(', '),
                                      maxLines: 1,
                                      overflow:
                                      TextOverflow.ellipsis,
                                      softWrap: false,
                                      style: const TextStyle(
                                        fontFamily:
                                        'Poppins Medium',
                                        fontSize: 15,
                                        color: Colors.white54,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      /* ---------- SLIDER ---------- */

                      Selector<PlayerController, Duration>(
                        selector: (_, p) => p.position,
                        builder: (_, position, __) {
                          final player =
                          context.read<PlayerController>();
                          final duration = player.duration;
                          final buffered =
                              player.bufferedPosition;

                          return SliderTheme(
                            data: SliderTheme.of(context)
                                .copyWith(
                              overlayShape:
                              SliderComponentShape
                                  .noOverlay,
                            ),
                            child: Slider(
                              activeColor: colorScheme.primary,
                              inactiveColor: Colors.white24,
                              secondaryActiveColor:
                              Colors.white38,
                              value: position.inSeconds
                                  .toDouble()
                                  .clamp(
                                  0,
                                  duration.inSeconds
                                      .toDouble()),
                              secondaryTrackValue:
                              buffered.inSeconds
                                  .toDouble()
                                  .clamp(
                                  0,
                                  duration.inSeconds
                                      .toDouble()),
                              max: duration.inSeconds
                                  .toDouble()
                                  .clamp(
                                  1, double.infinity),
                              onChanged: (v) =>
                                  player.seek(Duration(
                                      seconds: v.toInt())),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 5),

                      Padding(
                        padding:
                        const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            Selector<PlayerController, Duration>(
                              selector: (_, p) => p.position,
                              builder: (_, position, __) =>
                                  Text(
                                    _format(position),
                                    style: const TextStyle(
                                        fontSize: 12),
                                  ),
                            ),
                            Selector<PlayerController, Duration>(
                              selector: (_, p) => p.duration,
                              builder: (_, duration, __) =>
                                  Text(
                                    _format(duration),
                                    style: const TextStyle(
                                        fontSize: 12),
                                  ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 15),

                      /* ---------- CONTROLS ---------- */

                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          Selector<PlayerController, bool>(
                            selector: (_, p) =>
                            p.shuffleEnabled,
                            builder: (_, enabled, __) {
                              return IconButton(
                                padding: EdgeInsets.zero,
                                constraints:
                                const BoxConstraints(),
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
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints:
                            const BoxConstraints(),
                            iconSize: 34,
                            icon: const Icon(
                                Icons.skip_previous),
                            onPressed: context
                                .read<PlayerController>()
                                .previous,
                          ),
                          Selector<PlayerController, Map<String, dynamic>>(
                            selector: (_, p) => {
                              'playing': p.isPlaying,
                              'loading': p.shouldShowLoader,
                            },
                            builder: (_, state, __) {
                              final playing = state['playing'] as bool;
                              final showLoader = state['loading'] as bool;

                              final player = context.read<PlayerController>();

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
                                      AlwaysStoppedAnimation<Color>(
                                          Colors.grey),
                                    )
                                        : const SizedBox(),
                                  ),
                                  CircleAvatar(
                                    radius: 30,
                                    backgroundColor: Colors.white,
                                    child: IconButton(
                                      icon: Icon(
                                        playing ? Icons.pause : Icons.play_arrow,
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

                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints:
                            const BoxConstraints(),
                            iconSize: 34,
                            icon:
                            const Icon(Icons.skip_next),
                            onPressed: context
                                .read<PlayerController>()
                                .next,
                          ),
                          Selector<PlayerController,
                              RepeatMode>(
                            selector: (_, p) =>
                            p.repeatMode,
                            builder: (_, mode, __) {
                              return IconButton(
                                padding: EdgeInsets.zero,
                                constraints:
                                const BoxConstraints(),
                                icon: Icon(
                                  mode ==
                                      RepeatMode.one
                                      ? Icons.repeat_one
                                      : Icons.repeat,
                                  color: mode !=
                                      RepeatMode.off
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

                      const SizedBox(height: 25),

                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceAround,
                        children: [
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints:
                            const BoxConstraints(),
                            icon: const Icon(
                                Icons.favorite_border),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                                  content: Align(
                                    alignment: Alignment.center,
                                    child: Text('This feature is coming soon!',
                                      style: TextStyle(
                                          color: Colors.black
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints:
                            const BoxConstraints(),
                            icon: const Icon(
                                Icons.lyrics_outlined),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      LyricsPage(
                                        track: track,
                                      ),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints:
                            const BoxConstraints(),
                            icon: const Icon(
                                Icons.queue_music),
                            onPressed: () {
                              showModalBottomSheet(
                                useSafeArea: true,
                                context: context,
                                isScrollControlled:
                                true,
                                backgroundColor:
                                Colors.transparent,
                                builder: (_) =>
                                const QueueBottomSheet(),
                              );
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 25),

                      GestureDetector(
                        onTap: () =>
                            _showPlaybackInfo(context),
                        child: Column(
                          children: [
                            Text(
                              'Source: ${SourceManager.instance.activeSource.name}',
                              style: const TextStyle(
                                fontFamily:
                                'Poppins Medium',
                                fontSize: 11,
                                color: Colors.white54,
                              ),
                            ),
                            Selector<PlayerController,
                                String>(
                              selector: (_, p) =>
                              p.currentQualityLabel,
                              builder:
                                  (_, quality, __) =>
                                  Text(
                                    'Audio Quality: $quality',
                                    style:
                                    const TextStyle(
                                      fontFamily:
                                      'Poppins Medium',
                                      fontSize: 11,
                                      color: Colors.white54,
                                    ),
                                  ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 15),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  String _format(Duration d) {
    final m =
    d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s =
    d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Widget artworkImage(
      String? url, {
        required double size,
        double radius = 4,
      }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: FadeInImage(
        placeholder: const AssetImage(
            'assets/images/album_placeholder.jpg'),
        image: NetworkImage(url ?? ''),
        width: size,
        height: size,
        fit: BoxFit.cover,
        imageErrorBuilder: (_, __, ___) {
          return Image.asset(
            'assets/images/album_placeholder.jpg',
            width: size,
            height: size,
            fit: BoxFit.cover,
          );
        },
      ),
    );
  }
}
void _showPlaybackInfo(BuildContext context) {
  showDialog(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: const Color(0xFF1C1D22),
        title: const Text(
          'Playback Info',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow(
              'Source',
              SourceManager.instance.activeSource.name,
            ),
            _infoRow(
              'Audio Quality',
              globalPlayer.currentQualityLabel,
            ),
          ],
        ),
        actions: [
          Align(
            alignment: Alignment.center,
            child: TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ),
        ],
      );
    },
  );
}

Widget _infoRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$label:',
          style: const TextStyle(
            color: Colors.white54,
          ),
        ),
        Text(
          value,
          style: const TextStyle(color: Colors.white),
        ),
      ],
    ),
  );
}