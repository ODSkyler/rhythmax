import 'package:flutter/material.dart';
import 'package:rhythmax/core/models/album.dart';
import 'package:rhythmax/core/models/artist.dart';
import 'package:rhythmax/core/source/jiosaavn/jiosaavn_source.dart';
import 'package:rhythmax/core/source/source_manager.dart';
import 'package:rhythmax/ui/app_shell_page.dart';
import '../album/album_page.dart';

class ArtistAlbumsPage extends StatefulWidget {
  final Artist artist;
  final List<Album> albums;
  final List<Album> singles;
  final int initialTabIndex;

  const ArtistAlbumsPage({
    super.key,
    required this.artist,
    required this.albums,
    required this.singles,
    this.initialTabIndex = 0,
  });

  @override
  State<ArtistAlbumsPage> createState() => _ArtistAlbumsPageState();
}

class _ArtistAlbumsPageState extends State<ArtistAlbumsPage> {
  final List<Album> _albums = [];
  final List<Album> _singles = [];

  bool _loadingMore = false;
  bool _hasMore = true;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _albums.addAll(widget.albums);
    _singles.addAll(widget.singles);
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;

    setState(() => _loadingMore = true);

    final source = SourceManager.instance.activeSource;
    if (source is! JioSaavnSource) {
      setState(() {
        _loadingMore = false;
        _hasMore = false;
      });
      return;
    }

    final nextPage = _page + 1;

    final details = await source.getArtistDetails(
      widget.artist.id,
      page: nextPage,
    );

    // Filter duplicates
    final existingIds = {
      ..._albums.map((e) => e.id),
      ..._singles.map((e) => e.id),
    };

    final newAlbums = details.albums
        .where((a) => !existingIds.contains(a.id))
        .toList();

    final newSingles = details.singles
        .where((s) => !existingIds.contains(s.id))
        .toList();

    if (newAlbums.isEmpty && newSingles.isEmpty) {
      // 🚫 Backend repeating data → stop paging
      setState(() {
        _hasMore = false;
        _loadingMore = false;
      });
      return;
    }

    setState(() {
      _page = nextPage;
      _albums.addAll(newAlbums);
      _singles.addAll(newSingles);
      _loadingMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: widget.initialTabIndex,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => AppShellPage.of(context).popPage(),
          ),
          title: Text(widget.artist.name),
          bottom: TabBar(
            indicatorColor: Theme.of(context).colorScheme.primary,
            tabs: [
              Tab(text: 'Albums'),
              Tab(text: 'Singles & EPs'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _albumList(_albums),
            _albumList(_singles),
          ],
        ),
      ),
    );
  }

  Widget _albumList(List<Album> list) {
    if (list.isEmpty && !_loadingMore) {
      return const Center(
        child: Text(
          'Nothing here',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.pixels >=
            notification.metrics.maxScrollExtent - 200) {
          _loadMore();
        }
        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 100),
        itemCount: list.length + 1,
        itemBuilder: (context, index) {
          if (index == list.length) {
            return _footer();
          }

          final album = list[index];

          return InkWell(
            onTap: () {
              AppShellPage.of(context).pushPage(
                AlbumPage(album: album),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: FadeInImage(
                      placeholder: const AssetImage('assets/images/album_placeholder.jpg'),
                      image: NetworkImage(album.artworkUrl ?? ''),
                      width: 112,
                      height: 112,
                      fit: BoxFit.cover,

                      imageErrorBuilder: (_, __, ___) {
                        return Image.asset(
                          'assets/images/album_placeholder.jpg',
                          width: 112,
                          height: 112,
                          fit: BoxFit.cover,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          album.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          album.artists.join(', '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Poppins Medium',
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),

                        const SizedBox(height: 4),
                        if (album.releaseDate != null)
                          Text(
                            album.releaseDate!.year.toString(),
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _footer() {
    if (_loadingMore) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: Text(
            'Looking for more items…',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    if (!_hasMore) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: Text(
            'Feels like you’ve reached the end',
            style: TextStyle(color: Colors.white54),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
