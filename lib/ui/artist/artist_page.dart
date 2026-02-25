import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rhythmax/core/models/artist.dart';
import 'package:rhythmax/core/models/artist_details.dart';
import 'package:rhythmax/core/models/track.dart';
import 'package:rhythmax/core/models/album.dart';
import 'package:rhythmax/core/player/player_provider.dart';
import 'package:rhythmax/ui/album/album_page.dart';
import 'package:rhythmax/ui/artist/artist_songs_page.dart';
import 'package:rhythmax/ui/artist/artist_albums_page.dart';
import 'package:rhythmax/core/source/jiosaavn/jiosaavn_source.dart';
import 'package:rhythmax/ui/widget/track_options_sheet.dart';
import '../../core/source/source_manager.dart';
import '../app_shell_page.dart';

class ArtistDetailsPage extends StatefulWidget {
  final Artist artist;

  const ArtistDetailsPage({
    super.key,
    required this.artist,
  });

  @override
  State<ArtistDetailsPage> createState() => _ArtistDetailsPageState();
}

class _ArtistDetailsPageState extends State<ArtistDetailsPage> {
  bool _loading = true;
  late Artist _artist;

  List<Track> _topTracks = [];
  List<Album> _albums = [];
  List<Album> _singles = [];

  @override
  void initState() {
    super.initState();
    _artist = widget.artist;
    _loadArtist();
  }

  Future<void> _loadArtist() async {
    try {
      final source = SourceManager.instance.activeSource;
      if (source is! JioSaavnSource) return;

      final ArtistDetails details =
      await source.getArtistDetails(widget.artist.id);

      _topTracks = details.topTracks;
      _albums = details.albums;
      _singles = details.singles;
      _artist = details.artist;
    } catch (_) {}

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  void _playArtist() {
    if (_topTracks.isEmpty) return;

    final source = SourceManager.instance.activeSource;

    if (!source.explicitEnabled &&
        _topTracks.any((t) => t.isExplicit)) {
      _showExplicitBlockedDialog(context);
      return;
    }

    globalPlayer.playTrack(
      _topTracks.first,
      queue: _topTracks,
      sourceId: _artist.id,
      sourceType: 'artist',
      playType: 'THE ARTIST',
      sourceTitle: _artist.name,
    );
  }

  void _shuffleArtist() {
    if (_topTracks.isEmpty) return;

    final source = SourceManager.instance.activeSource;

    final playable = _topTracks
        .where((t) => !t.isExplicit || source.explicitEnabled)
        .toList();

    if (playable.isEmpty) {
      _showExplicitBlockedDialog(context);
      return;
    }

    playable.shuffle();

    globalPlayer.playTrack(
      playable.first,
      queue: playable,
      sourceId: _artist.id,
      sourceType: 'artist',
      playType: 'THE ARTIST',
      sourceTitle: _artist.name,
    );
  }

  /* -------------------------------------------------------------------------- */
  /*                                   UI                                       */
  /* -------------------------------------------------------------------------- */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
        slivers: [
          _appBar(),

          SliverToBoxAdapter(
            child: AnimatedBuilder(
              animation: Listenable.merge([
                globalPlayer,
                SourceManager.instance,
              ]),
              builder: (_, __) {
                final isThisArtistQueue =
                    globalPlayer.queueSourceType == 'artist' &&
                        globalPlayer.queueSourceId == _artist.id;

                final isPlayingThisArtist =
                    isThisArtistQueue && globalPlayer.isPlaying;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [

                      /// ❤️ LIKE
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.white24,
                        child: IconButton(
                          icon: const Icon(Icons.favorite_border),
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
                          if (_topTracks.isEmpty) return;

                          if (isThisArtistQueue) {
                            if (globalPlayer.isPlaying) {
                              globalPlayer.pause();
                            } else {
                              globalPlayer.play();
                            }
                            return;
                          }

                          _playArtist();
                        },
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor:
                          Theme.of(context).colorScheme.primary,
                          child: Icon(
                            isPlayingThisArtist
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
                          icon: const Icon(Icons.shuffle),
                          color: Colors.white,
                          onPressed: _shuffleArtist,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          _sectionTitle(
            'Popular tracks',
            onTap: () {
              AppShellPage.of(context).pushPage(
                ArtistSongsPage(
                  artist: widget.artist,
                  tracks: _topTracks,
                ),
              );
            },
          ),

          _topTracks.isEmpty
              ? const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'NO TOP TRACKS',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          )
              : _trackList(
            visibleTracks: _topTracks.take(5).toList(),
            fullQueue: _topTracks,
            artistId: _artist.id,
            artistName: _artist.name,
          ),

          _sectionTitle(
            'Albums',
            onTap: () {
              AppShellPage.of(context).pushPage(
                ArtistAlbumsPage(
                  artist: widget.artist,
                  albums: _albums,
                  singles: _singles,
                  initialTabIndex: 0,
                ),
              );
            },
          ),

          _albums.isEmpty
              ? const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'NO ALBUMS',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          )
              : _albumRow(_albums.take(10).toList()),

          _sectionTitle(
            'Singles & EPs',
            onTap: () {
              AppShellPage.of(context).pushPage(
                ArtistAlbumsPage(
                  artist: widget.artist,
                  albums: _albums,
                  singles: _singles,
                  initialTabIndex: 1,
                ),
              );
            },
          ),

          _singles.isEmpty
              ? const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'NO SINGLES',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          )
              : _albumRow(_singles.take(10).toList()),

          const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
        ],
       ),
    );
  }

  /* -------------------------------------------------------------------------- */
  /*                               SLIVER APP BAR                               */
  /* -------------------------------------------------------------------------- */

  Widget _appBar() {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 420,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle.light,

      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          AppShellPage.of(context).popPage();
        },
      ),

      actions: const [
        Padding(
          padding: EdgeInsets.only(right: 12),
          child: Icon(Icons.more_vert),
        ),
      ],

      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        centerTitle: true,
        titlePadding: const EdgeInsets.only(bottom: 16),
        title: Text(
          widget.artist.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w700,
          ),
        ),

        background: Stack(
          fit: StackFit.expand,
          children: [
            // Hero image (no empty frame while loading)
            FadeInImage(
              placeholder: const AssetImage('assets/images/artist_placeholder.jpg'),
              image: NetworkImage(_artist.artworkUrl ?? ''),
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,

              imageErrorBuilder: (_, __, ___) {
                return Image.asset(
                  'assets/images/artist_placeholder.jpg',
                  fit: BoxFit.cover,
                );
              },
            ),

            // Gradient overlay
             DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Theme.of(context).scaffoldBackgroundColor,
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }



  /* -------------------------------------------------------------------------- */
  /*                               SECTIONS                                     */
  /* -------------------------------------------------------------------------- */

  SliverToBoxAdapter _sectionTitle(
      String title, {
        VoidCallback? onTap,
      }) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (onTap != null)
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: onTap,
              ),
          ],
        ),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                               TRACK LIST                                   */
/* -------------------------------------------------------------------------- */

SliverList _trackList({
  required List<Track> visibleTracks,
  required List<Track> fullQueue,
  required String artistId,
  required String artistName,
}) {
  return SliverList(
    delegate: SliverChildBuilderDelegate(
          (context, index) {
        final track = visibleTracks[index];

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

            final bool explicitBlocked =
                track.isExplicit && !source.explicitEnabled;

            return ListTile(
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 0),

              leading: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: FadeInImage(
                  placeholder: const AssetImage(
                      'assets/images/album_placeholder.jpg'),
                  image: NetworkImage(track.artworkUrl ?? ''),
                  width: 55,
                  height: 55,
                  fit: BoxFit.cover,
                  imageErrorBuilder: (_, __, ___) => Image.asset(
                    'assets/images/album_placeholder.jpg',
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
                  isCurrent ? FontWeight.w700 : FontWeight.w500,
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
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
                    ),
                  );
                },
              ),

              onTap: () {
                if (explicitBlocked) {
                  _showExplicitBlockedDialog(context);
                  return;
                }

                final isThisArtistQueue =
                    globalPlayer.queueSourceType == 'artist' &&
                        globalPlayer.queueSourceId == artistId;

                if (isThisArtistQueue) {
                  globalPlayer.playFromCurrentQueue(track);
                  return;
                }

                globalPlayer.playTrack(
                  track,
                  queue: fullQueue,
                  sourceId: artistId,
                  sourceType: 'artist',
                  playType: 'THE ARTIST',
                  sourceTitle: artistName,
                );
              },
            );
          },
        );
      },
      childCount: visibleTracks.length,
    ),
  );
}


/* -------------------------------------------------------------------------- */
/*                               ALBUM ROW                                    */
/* -------------------------------------------------------------------------- */

SliverToBoxAdapter _albumRow(List<Album> albums) {
  return SliverToBoxAdapter(
    child: SizedBox(
      height: 210,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: albums.length,
        itemBuilder: (context, index) {
          final album = albums[index];

          return GestureDetector(
            onTap: () {
              AppShellPage.of(context).pushPage(
                AlbumPage(album: album),
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 140,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: FadeInImage(
                        placeholder: const AssetImage('assets/images/album_placeholder.jpg'),
                        image: NetworkImage(album.artworkUrl ?? ''),
                        height: 140,
                        width: 140,
                        fit: BoxFit.cover,

                        imageErrorBuilder: (_, __, ___) {
                          return Image.asset(
                            'assets/images/album_placeholder.jpg',
                            height: 140,
                            width: 140,
                            fit: BoxFit.cover,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      album.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      album.artists.join(', '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}
void _showExplicitBlockedDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Explicit content'),
      content: const Text(
        'This contains explicit content.\n\n'
            'To access this content, enable Explicit Content '
            'in the active source settings.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
