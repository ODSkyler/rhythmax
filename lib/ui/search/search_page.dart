import 'package:flutter/material.dart';
import 'package:rhythmax/core/source/source_manager.dart';
import 'package:rhythmax/core/player/player_provider.dart';
import 'package:rhythmax/core/models/track.dart';
import 'package:rhythmax/core/models/album.dart';
import 'package:rhythmax/core/models/artist.dart';
import 'package:rhythmax/core/models/playlist.dart';
import 'package:rhythmax/ui/playlist/playlist_page.dart';
import 'package:rhythmax/ui/artist/artist_page.dart';
import 'package:rhythmax/ui/album/album_page.dart';
import 'package:rhythmax/ui/widget/track_options_sheet.dart';
import 'package:rhythmax/ui/app_shell_page.dart';
import 'source_picker_sheet.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late final TabController _tabController;

  List<Track> _tracks = [];
  List<Album> _albums = [];
  List<Artist> _artists = [];
  List<Playlist> _playlists = [];

  bool _loading = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  /* ---------------- SEARCH ---------------- */

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _loading = true;
      _hasSearched = true;
    });

    final source = SourceManager.instance.activeSource;

    final tracks = await source.searchTracks(query);
    final albums = await source.searchAlbums(query);
    final artists = await source.searchArtists(query);
    final playlists = await source.searchPlaylists(query);

    if (!mounted) return;

    setState(() {
      _tracks = tracks;
      _albums = albums;
      _artists = artists;
      _playlists = playlists;
      _loading = false;
    });
  }

  /* ---------------- SOURCE SWITCH ---------------- */

  Future<void> _changeSource() async {
    await showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      backgroundColor: const Color(0xFF1C1D22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const SourcePickerSheet(),
    );

    setState(() {});

    if (_searchController.text.trim().isNotEmpty) {
      _performSearch();
    }
  }

  /* ---------------- UI ---------------- */

  @override
  Widget build(BuildContext context) {
    final source = SourceManager.instance.activeSource;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            /* ---------------- APP BAR ---------------- */

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Search',
                      style: TextStyle(
                        fontSize: 32,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _changeSource,
                    icon: Image.asset(
                      _sourceIconFor(source.id),
                      width: 30,
                      height: 30,
                    ),
                  ),
                ],
              ),
            ),

            /* ---------------- SEARCH FIELD ---------------- */

            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _performSearch(),
                decoration: InputDecoration(
                  hintText: 'Search on ${source.name}',
                  hintStyle: TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white12,
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _tracks.clear();
                        _albums.clear();
                        _hasSearched = false;
                      });
                    },
                  )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            /* ---------------- TABS ---------------- */

            TabBar(
              controller: _tabController,
              indicatorColor: Theme.of(context).colorScheme.primary,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              tabs: const [
                Tab(text: 'Tracks'),
                Tab(text: 'Albums'),
                Tab(text: 'Artists'),
                Tab(text: 'Playlists'),
              ],
            ),

            /* ---------------- RESULTS ---------------- */

            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : !_hasSearched
                  ? const Center(
                child: Text(
                  'Search for Tracks / Albums / Artists / Playlists',
                  style: TextStyle(
                      color: Colors.white70,
                      fontFamily: 'Poppins Medium'
                  ),
                ),
              )
                  : TabBarView(
                controller: _tabController,
                children: [
                  _tracksTab(),
                  _albumsTab(),
                  _artistsTab(),
                  _playlistsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /* ---------------- TRACKS TAB ---------------- */

  Widget _tracksTab() {
    if (_tracks.isEmpty) {
      return const Center(
        child: Text(
          'No tracks found',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return ListView.builder(
      itemCount: _tracks.length,
      itemBuilder: (context, index) {
        final track = _tracks[index];

        return AnimatedBuilder(
          animation: Listenable.merge([
            globalPlayer,
            SourceManager.instance,
          ]),
          builder: (_, __) {
            final isCurrent =
                globalPlayer.currentTrack?.id == track.id;

            final source = SourceManager.instance.activeSource;

            final bool explicitBlocked =
                track.isExplicit && !source.explicitEnabled;

            return ListTile(
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 2),

              leading: _trackArtwork(track.artworkUrl, 56),

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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
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
                  showDialog(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Explicit Content'),
                      content: const Text(
                        'This contains explicit content.\n\n'
                            'Enable explicit content in source settings.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                  return;
                }

                globalPlayer.playTrack(
                  track,
                  queue: _tracks,
                  sourceType: 'search',
                  playType: 'THE SEARCH',
                  sourceTitle: _searchController.text,
                );
              },
            );
          },
        );
      },
    );
  }


  /* ---------------- ALBUMS TAB ---------------- */

  Widget _albumsTab() {
    if (_albums.isEmpty) {
      return const Center(
        child:
        Text('No albums found', style: TextStyle(color: Colors.white70)),
      );
    }

    return ListView.builder(

      itemCount: _albums.length,
      itemBuilder: (context, index) {
        final album = _albums[index];

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          leading: _artwork(album.artworkUrl, 56),
          title: Text(album.title,
              maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            album.artists.join(', '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontFamily: 'Poppins Medium',
                color: Colors.white70,
                fontSize: 13
            ),
          ),
          trailing: const Icon(Icons.more_vert, size: 18),
          onTap: () {
            AppShellPage.of(context).pushPage(
              AlbumPage(album: album),
            );
          },
        );
      },
    );
  }

  /* --------------- ARTIST TAB ----------------*/

  Widget _artistsTab() {
    if (_artists.isEmpty) {
      return const Center(
        child: Text(
          'No artists found',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _artists.length,
      itemBuilder: (context, index) {
        final artist = _artists[index];

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 2),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: FadeInImage(
              placeholder: const AssetImage('assets/images/artist_placeholder.jpg'),
              image: NetworkImage(artist.artworkUrl ?? ''),
              width: 56,
              height: 56,
              fit: BoxFit.cover,

              imageErrorBuilder: (_, __, ___) {
                return Image.asset(
                  'assets/images/artist_placeholder.jpg',
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                );
              },
            ),
          ),

          title: Text(
            artist.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: const Text(
            'Artist',
            style: TextStyle(
              fontFamily: 'Poppins Medium',
                color: Colors.white70,
                fontSize: 13
            ),
          ),
          trailing: const Icon(Icons.more_vert, size: 18),
          onTap: () {
            AppShellPage.of(context).pushPage(
              ArtistDetailsPage(artist: artist),
            );
          },
        );
      },
    );
  }


  /* -------------- PLAYLIST TAB ---------------*/

  Widget _playlistsTab() {
    if (_playlists.isEmpty) {
      return const Center(
        child: Text(
          'No playlists found',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return ListView.builder(
      itemCount: _playlists.length,
      itemBuilder: (context, index) {
        final playlist = _playlists[index];

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),

          leading: _playlistArtwork(
            playlist.artworkUrl,
            56,
          ),

          title: Text(
            playlist.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          subtitle: Text(
            playlist.description ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Poppins Medium',
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
          trailing: const Icon(Icons.more_vert, size: 18),
          onTap: () {
            AppShellPage.of(context).pushPage(
              PlaylistPage(playlist: playlist),
            );
          },
        );
      },
    );
  }

  /* ---------------- HELPERS ---------------- */

  Widget _artwork(String? url, double size) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: FadeInImage(
        placeholder: const AssetImage('assets/images/album_placeholder.jpg'),
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


  Widget _trackArtwork(String? url, double size) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: FadeInImage(
        placeholder: const AssetImage('assets/images/music_placeholder.jpg'),
        image: NetworkImage(url ?? ''),
        width: size,
        height: size,
        fit: BoxFit.cover,

        imageErrorBuilder: (_, __, ___) {
          return Image.asset(
            'assets/images/music_placeholder.jpg',
            width: size,
            height: size,
            fit: BoxFit.cover,
          );
        },
      ),
    );
  }


  Widget _playlistArtwork(String? url, double size) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: FadeInImage(
        placeholder: const AssetImage('assets/images/placeholder.jpg'),
        image: NetworkImage(url ?? ''),
        width: size,
        height: size,
        fit: BoxFit.cover,

        imageErrorBuilder: (_, __, ___) {
          return Image.asset(
            'assets/images/placeholder.jpg',
            width: size,
            height: size,
            fit: BoxFit.cover,
          );
        },
      ),
    );
  }



  String _sourceIconFor(String sourceId) {
    switch (sourceId) {
      case 'jiosaavn':
        return 'assets/images/jiosaavn.png';
      case 'youtube_music':
        return 'assets/images/youtube_music.png';
      case 'tidal_binilossless':
        return 'assets/images/tidal.png';
      default:
        return 'assets/images/music_placeholder.jpg';
    }
  }
}
