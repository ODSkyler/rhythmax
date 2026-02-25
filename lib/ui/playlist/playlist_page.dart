import 'package:flutter/material.dart';
import 'package:rhythmax/core/models/playlist.dart';
import 'package:rhythmax/core/models/track.dart';
import 'package:rhythmax/core/source/source_manager.dart';
import 'package:rhythmax/core/player/player_provider.dart';
import 'package:rhythmax/ui/widget/track_options_sheet.dart';
import 'package:rhythmax/ui/app_shell_page.dart';

class PlaylistPage extends StatefulWidget {
  final Playlist playlist;

  const PlaylistPage({super.key, required this.playlist});

  @override
  State<PlaylistPage> createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  late Playlist _playlist;
  bool _loading = true;
  bool _collapsed = false;

  Duration get _totalDuration {
    return _playlist.tracks.fold(
      Duration.zero,
          (sum, t) => sum + t.duration,
    );
  }

  String _formatDuration(Duration total) {
    final minutes = total.inMinutes;

    if (minutes < 60) {
      return '$minutes min';
    }

    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;

    if (remainingMinutes == 0) {
      return '$hours hr';
    }

    return '$hours hr $remainingMinutes min';
  }

  String _trackMetaText() {
    if (_loading) return 'Loading tracks...';

    final count = _playlist.tracks.length;

    if (count == 0) return 'No tracks';

    final trackText = count == 1 ? '1 track' : '$count tracks';
    final durationText = _formatDuration(_totalDuration);

    return '$trackText • $durationText';
  }


  @override
  void initState() {
    super.initState();
    _playlist = widget.playlist;
    _loadPlaylist();
  }

  Future<void> _loadPlaylist() async {
    try {
      final source = SourceManager.instance.activeSource;
      final full = await source.getPlaylist(_playlist.id);

      if (!mounted) return;

      setState(() {
        _playlist = full;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  void _playPlaylist() {
    if (_playlist.tracks.isEmpty) return;

    final source = SourceManager.instance.activeSource;

    if (!source.explicitEnabled &&
        _playlist.tracks.any((t) => t.isExplicit)) {
      _showExplicitBlockedDialog(context);
      return;
    }

    globalPlayer.playTrack(
      _playlist.tracks.first,
      queue: _playlist.tracks,
      sourceId: _playlist.id,
      sourceType: 'playlist',
      playType: 'THE PLAYLIST',
      sourceTitle: _playlist.title,
    );
  }

  void _shufflePlaylist() {
    if (_playlist.tracks.isEmpty) return;

    final source = SourceManager.instance.activeSource;

    if (!source.explicitEnabled &&
        _playlist.tracks.any((t) => t.isExplicit)) {
      _showExplicitBlockedDialog(context);
      return;
    }

    final tracks = [..._playlist.tracks]..shuffle();

    globalPlayer.playTrack(
      tracks.first,
      queue: tracks,
      sourceId: _playlist.id,
      sourceType: 'playlist',
      playType: 'THE PLAYLIST',
      sourceTitle: _playlist.title,
    );
  }


  @override
  Widget build(BuildContext context) {
    final playlist = _playlist;

    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n.metrics.pixels > 260 && !_collapsed) {
            setState(() => _collapsed = true);
          } else if (n.metrics.pixels <= 260 && _collapsed) {
            setState(() => _collapsed = false);
          }
          return false;
        },
        child: CustomScrollView(
          slivers: [
            _appBar(playlist),
            _header(playlist),

            /// 🔥 realtime play button
            _playButton(playlist),

            /// 🔥 realtime track list
            _trackList(playlist),

            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  /* ---------------- APP BAR ---------------- */

  SliverAppBar _appBar(Playlist playlist) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => AppShellPage.of(context).popPage(),
      ),
      title: AnimatedOpacity(
        opacity: _collapsed ? 1 : 0,
        duration: const Duration(milliseconds: 200),
        child: Text(
          playlist.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  /* ---------------- HEADER ---------------- */

  SliverToBoxAdapter _header(Playlist playlist) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FadeInImage(
                  placeholder:
                  const AssetImage('assets/images/placeholder.jpg'),
                  image: NetworkImage(playlist.artworkUrl ?? ''),
                  width: 320,
                  height: 320,
                  fit: BoxFit.cover,
                  imageErrorBuilder: (_, __, ___) => Image.asset(
                    'assets/images/placeholder.jpg',
                    width: 320,
                    height: 320,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              playlist.title,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              playlist.description ?? '',
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontFamily: 'Poppins Medium',
                  color: Colors.white70
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _trackMetaText(),
              style: const TextStyle(
                  fontFamily: 'Poppins Medium',
                  color: Colors.white54
              ),
            ),
          ],
        ),
      ),
    );
  }

  /* ---------------- PLAY BUTTON (REALTIME) ---------------- */

  SliverToBoxAdapter _playButton(Playlist playlist) {
    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: Listenable.merge([
          globalPlayer,
          SourceManager.instance,
        ]),
        builder: (_, __) {
          final isThisPlaylistQueue =
              globalPlayer.queueSourceType == 'playlist' &&
                  globalPlayer.queueSourceId == _playlist.id;

          final isPlayingThisPlaylist =
              isThisPlaylistQueue && globalPlayer.isPlaying;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [

                /// ❤️ FAVORITE (placeholder)
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white24,
                  child: IconButton(
                    icon: const Icon(Icons.favorite_border, size: 24),
                    color: Colors.white,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor:
                          Theme.of(context).colorScheme.primary,
                          content: const Center(
                            child: Text(
                              'This feature is coming soon!',
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                /// ▶ PLAY / ⏸ PAUSE
                GestureDetector(
                  onTap: () {
                    if (_playlist.tracks.isEmpty) return;

                    final isThisPlaylistQueue =
                        globalPlayer.queueSourceType == 'playlist' &&
                            globalPlayer.queueSourceId == _playlist.id;

                    if (isThisPlaylistQueue) {
                      if (globalPlayer.isPlaying) {
                        globalPlayer.pause();     // ⏸ pause current
                      } else {
                        globalPlayer.play();      // ▶ resume from same position
                      }
                      return;
                    }

                    // ▶ start playlist fresh
                    _playPlaylist();
                  },
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor:
                    Theme.of(context).colorScheme.primary,
                    child: Icon(
                      isPlayingThisPlaylist
                          ? Icons.pause
                          : Icons.play_arrow,
                      size: 34,
                      color: Colors.black,
                    ),
                  ),
                ),

                /// 🔀 SHUFFLE
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white24,
                  child: IconButton(
                    icon: const Icon(Icons.shuffle, size: 24),
                    color: Colors.white,
                    onPressed: _shufflePlaylist,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /* ---------------- TRACK LIST (REALTIME) ---------------- */

  SliverList _trackList(Playlist playlist) {
    if (_loading) {
      return const SliverList(
        delegate: SliverChildListDelegate.fixed([
          Padding(
            padding: EdgeInsets.only(top: 32),
            child: Center(child: CircularProgressIndicator()),
          ),
        ]),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          final Track track = playlist.tracks[index];

          return AnimatedBuilder(
            animation: Listenable.merge([
              globalPlayer,
              SourceManager.instance,
            ]),
            builder: (_, __) {
              final bool isCurrent =
                  globalPlayer.currentTrack?.id == track.id;

              final source =
                  SourceManager.instance.activeSource;

              final explicitBlocked =
                  track.isExplicit && !source.explicitEnabled;

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 1),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: FadeInImage(
                    placeholder: const AssetImage(
                        'assets/images/music_placeholder.jpg'),
                    image: NetworkImage(track.artworkUrl ?? ''),
                    width: 55,
                    height: 55,
                    fit: BoxFit.cover,
                    imageErrorBuilder: (_, __, ___) => Image.asset(
                      'assets/images/music_placeholder.jpg',
                      width: 55,
                      height: 55,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                title: Text(
                  track.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isCurrent
                        ? Theme.of(context).colorScheme.primary
                        : explicitBlocked
                        ? Colors.white30
                        : Colors.white,
                    fontWeight:
                    isCurrent ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
                subtitle: Row(
                  children: [
                    if (track.isExplicit)
                      Padding(
                        padding: const EdgeInsets.only(right: 3),
                        child: const Icon(
                          Icons.explicit,
                          size: 13,
                          color: Colors.grey,
                        ),
                      ),

                    Expanded(
                      child: Text(
                        track.artists.join(', '),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Poppins Medium',
                          color: Colors.white54,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.more_vert, size: 18),
                  onPressed: () {
                    showModalBottomSheet(
                      useSafeArea: true,
                      useRootNavigator: true,
                      context: context,
                      backgroundColor: Colors.transparent,
                      isScrollControlled: true,
                      builder: (_) => TrackOptionsSheet(
                        track: track,
                        shell: AppShellPage.of(context),
                      ),
                    );
                  },
                ),
                onTap: () {
                  if (explicitBlocked) {
                    _showExplicitBlockedDialog(context);
                    return;
                  }

                  final isThisPlaylistQueue =
                      globalPlayer.queueSourceType == 'playlist' &&
                          globalPlayer.queueSourceId == _playlist.id;

                  if (isThisPlaylistQueue) {
                    globalPlayer.playFromCurrentQueue(track);
                    return;
                  }

                  globalPlayer.playTrack(
                    track,
                    queue: _playlist.tracks,
                    sourceId: _playlist.id,
                    sourceType: 'playlist',
                    playType: 'THE PLAYLIST',
                    sourceTitle: playlist.title,
                  );
                },
              );
            },
          );
        },
        childCount: playlist.tracks.length,
      ),
    );
  }

  void _showExplicitBlockedDialog(BuildContext context) {
    if (!mounted) return;

    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Explicit Content'),
        content: const Text(
          'Enable explicit content in the active source settings.',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext, rootNavigator: true).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
} // placeholder for liked is assets/images/liked.jpg