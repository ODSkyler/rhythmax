import 'package:flutter/material.dart';
import 'package:rhythmax/core/player/player_provider.dart';
import 'package:rhythmax/core/theme/theme_scope.dart';
import 'package:rhythmax/ui/player/full_player_page.dart';
import 'package:rhythmax/ui/widget/overflow_marquee_text.dart';
import 'package:rhythmax/ui/app_shell_page.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = ThemeScope.of(context);

    return AnimatedBuilder(
      animation: globalPlayer,
      builder: (context, _) {
        final track = globalPlayer.currentTrack;
        if (track == null) return const SizedBox.shrink();

        final progress = globalPlayer.duration.inMilliseconds == 0
            ? 0.0
            : globalPlayer.position.inMilliseconds /
            globalPlayer.duration.inMilliseconds;

        return Material(
          color: themeController.backgroundColor,
          elevation: 12,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /* ---------------- PROGRESS BAR ---------------- */

              LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 2,
                backgroundColor: Colors.white12,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),

              /* ---------------- CONTENT ---------------- */

              InkWell(
                onTap: () {
                  final shell = AppShellPage.of(context);
                  shell.pushPage(const FullPlayerPage());
                },
                child: SizedBox(
                  height: 64,
                  child: Row(
                    children: [
                      const SizedBox(width: 8),

                      /* ---------- ALBUM ART ---------- */

                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: FadeInImage(
                          placeholder: const AssetImage('assets/images/album_placeholder.jpg'),
                          image: NetworkImage(track.artworkUrl ?? ''),
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,

                          imageErrorBuilder: (_, __, ___) {
                            return Image.asset(
                              'assets/images/album_placeholder.jpg',
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),

                      /* ---------- TITLE + ARTIST ---------- */

                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            OverflowMarqueeText(
                              text: track.title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
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
                                      size: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                Expanded(
                                  child: Text(
                                    track.artists.join(', '),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    softWrap: false,
                                    style: const TextStyle(
                                      fontFamily: 'Poppins Medium',
                                      fontSize: 12,
                                      color: Colors.white54,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      /* ---------- PLAY / BUFFER ---------- */

                      Stack(
                        alignment: Alignment.center,
                        children: [
                          if (globalPlayer.isLoading ||
                              globalPlayer.isBuffering)
                            const SizedBox(
                              width: 45,
                              height: 45,
                              child: CircularProgressIndicator(
                                strokeWidth: 5,
                                valueColor:
                                AlwaysStoppedAnimation<Color>(
                                  Colors.white70,
                                ),
                              ),
                            ),
                          IconButton(
                            icon: Icon(
                              globalPlayer.isPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              globalPlayer.isPlaying
                                  ? globalPlayer.pause()
                                  : globalPlayer.play();
                            },
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_next),
                        color: Colors.white,
                        onPressed: globalPlayer.next,
                      ),
                      const SizedBox(width: 4),
                    ],
                  ),
                ),
              ),
              Divider(
                height: 0,
                color: Colors.white10,
              )
            ],
          ),
        );
      },
    );
  }
}

