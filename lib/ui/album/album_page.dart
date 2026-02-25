import 'package:flutter/material.dart';
import 'package:rhythmax/core/models/album.dart';
import 'package:rhythmax/core/player/player_provider.dart';
import 'package:rhythmax/core/source/source_manager.dart';
import 'package:rhythmax/ui/widget/track_options_sheet.dart';
import 'package:rhythmax/ui/app_shell_page.dart';

class AlbumPage extends StatefulWidget {
  final Album album;

  const AlbumPage({super.key, required this.album});

  @override
  State<AlbumPage> createState() => _AlbumPageState();
}

class _AlbumPageState extends State<AlbumPage> {
  late Album _album;
  late BuildContext _pageContext;
  bool _collapsed = false;
  bool _loadingTracks = false;

  @override
  void initState() {
    super.initState();
    _album = widget.album;

    if (_album.tracks.isEmpty) {
      _loadFullAlbum();
    }
  }

  Future<void> _loadFullAlbum() async {
    setState(() => _loadingTracks = true);

    final source = SourceManager.instance.activeSource;
    final fullAlbum = await source.getAlbum(_album.id);

    if (!mounted) return;

    setState(() {
      _album = fullAlbum;
      _loadingTracks = false;
    });
  }

  void _playAlbumShuffled() {
    if (_album.tracks.isEmpty) return;

    final source = SourceManager.instance.activeSource;

    final playable = _album.tracks
        .where((t) => !(t.isExplicit && !source.explicitEnabled))
        .toList();

    if (playable.isEmpty) {
      _showExplicitBlockedDialog(_pageContext);
      return;
    }

    playable.shuffle();
    final randomTrack = playable.first;

    globalPlayer.playTrack(
      randomTrack,
      queue: playable,
      playType: 'THE ALBUM',
      sourceTitle: _album.title,
    );
  }


  Duration get _totalDuration {
    return _album.tracks.fold(
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
    if (_loadingTracks) return 'Loading tracks...';

    final count = _album.tracks.length;

    if (count == 0) return 'No tracks';

    final trackText = count == 1 ? '1 track' : '$count tracks';
    final durationText = _formatDuration(_totalDuration);

    return '$trackText • $durationText';
  }


  @override
  Widget build(BuildContext context) {
    _pageContext = context;
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
            _appBar(),
            _albumHeader(),

            /// 🔥 reactive play button
            _playButton(),

            _trackHeader(),

            /// 🔥 reactive track list
            _trackList(),

            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  /* ---------------- APP BAR ---------------- */

  SliverAppBar _appBar() {
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => AppShellPage.of(context).popPage(),
      ),
      title: AnimatedOpacity(
        opacity: _collapsed ? 1 : 0,
        duration: const Duration(milliseconds: 200),
        child: Text(
          _album.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  /* ---------------- HEADER ---------------- */

  SliverToBoxAdapter _albumHeader() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: FadeInImage(
                  placeholder: const AssetImage(
                      'assets/images/album_placeholder.jpg'),
                  image: NetworkImage(_album.artworkUrl ?? ''),
                  width: 320,
                  height: 320,
                  fit: BoxFit.cover,
                  imageErrorBuilder: (_, __, ___) => Image.asset(
                    'assets/images/album_placeholder.jpg',
                    width: 320,
                    height: 320,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _album.title,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _album.artists.join(', '),
              style: const TextStyle(
                  fontFamily: 'Poppins Medium',
                  color: Colors.white70,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _album.releaseDate?.year.toString() ?? '',
              style: const TextStyle(
                fontFamily: 'Poppins Medium',
                color: Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /* ---------------- PLAY BUTTON (REALTIME) ---------------- */

  SliverToBoxAdapter _playButton() {
    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: Listenable.merge([
          globalPlayer,
          SourceManager.instance,
        ]),
        builder: (_, __) {
          final current = globalPlayer.currentTrack;

          final isPlayingThisAlbum =
              current != null &&
                  globalPlayer.isPlaying &&
                  _album.tracks.any((t) => t.id == current.id);

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor:
                  Colors.white24,
                  child: IconButton(
                    icon: const Icon(Icons.favorite_border, size: 24,),
                    color: Colors.white,
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
                    }
                  ),
                ),
                /// ▶ PLAY / ⏸ PAUSE
                GestureDetector(
                  onTap: () {
                    if (_album.tracks.isEmpty) return;

                    final source = SourceManager.instance.activeSource;

                    if (!source.explicitEnabled &&
                        _album.tracks.any((t) => t.isExplicit)) {
                      _showExplicitBlockedDialog(_pageContext);
                      return;
                    }

                    final isThisAlbumQueue =
                        globalPlayer.queueSourceType == 'album' &&
                            globalPlayer.queueSourceId == _album.id;

                    if (isThisAlbumQueue) {
                      if (globalPlayer.isPlaying) {
                        globalPlayer.pause();
                      } else {
                        globalPlayer.play(); // ⭐ RESUME INSTEAD OF RESTART
                      }
                      return;
                    }

                    // ▶ Start album fresh
                    globalPlayer.playTrack(
                      _album.tracks.first,
                      queue: _album.tracks,
                      sourceId: _album.id,
                      sourceType: 'album',
                      playType: 'THE ALBUM',
                      sourceTitle: _album.title,
                    );
                  },
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor:
                    Theme.of(context).colorScheme.primary,
                    child: Icon(
                      isPlayingThisAlbum
                          ? Icons.pause
                          : Icons.play_arrow,
                      size: 34,
                      color: Colors.black,
                    ),
                  ),
                ),

                /// 🔀 SHUFFLE BUTTON

                CircleAvatar(
                  radius: 24,
                  backgroundColor:
                  Colors.white24,
                  child: IconButton(
                    icon: const Icon(Icons.shuffle, size: 24,),
                    color: Colors.white,
                    onPressed: _playAlbumShuffled,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }


  /* ---------------- TRACK HEADER ---------------- */

  SliverToBoxAdapter _trackHeader() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
        child: Text(
          _trackMetaText(),
          style: const TextStyle(
              color: Colors.white54,
              fontFamily: 'Poppins Medium'
          ),
        ),
      ),
    );
  }

  /* ---------------- TRACK LIST (REALTIME) ---------------- */

  SliverList _trackList() {
    if (_loadingTracks) {
      return const SliverList(
        delegate: SliverChildListDelegate.fixed([
          Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          )
        ]),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          final track = _album.tracks[index];

          return AnimatedBuilder(
            animation: Listenable.merge([
              globalPlayer,
              SourceManager.instance,
            ]),
            builder: (_, __) {
              final isCurrent =
                  globalPlayer.currentTrack?.id == track.id;

              final source =
                  SourceManager.instance.activeSource;

              final explicitBlocked =
                  track.isExplicit && !source.explicitEnabled;

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 1),
                leading: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: isCurrent
                        ? Theme.of(context).colorScheme.primary
                        : Colors.white38,
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
                        style:
                        const TextStyle(
                            fontFamily: 'Poppins Medium',
                            color: Colors.white54
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
                        showAlbum: false,
                      ),
                    );
                  },
                ),
                onTap: () {
                  if (explicitBlocked) {
                    _showExplicitBlockedDialog(context);
                    return;
                  }

                  final isThisAlbumQueue =
                      globalPlayer.queueSourceType == 'album' &&
                          globalPlayer.queueSourceId == _album.id;

                  if (isThisAlbumQueue) {
                    globalPlayer.playFromCurrentQueue(track);
                    return;
                  }

                  globalPlayer.playTrack(
                    track,
                    queue: _album.tracks,
                    sourceId: _album.id,
                    sourceType: 'album',
                    playType: 'THE ALBUM',
                    sourceTitle: _album.title,
                  );
                },
              );
            },
          );
        },
        childCount: _album.tracks.length,
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


}
