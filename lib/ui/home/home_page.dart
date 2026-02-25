import 'package:flutter/material.dart';
import '../../core/source/source_manager.dart';
import '../../core/models/home_section.dart';
import '../../core/models/home_item.dart';
import '../app_shell_page.dart';
import '../album/album_page.dart';
import '../playlist/playlist_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _loading = true;
  List<HomeSection> _sections = [];

  @override
  void initState() {
    super.initState();
    _loadHome();

    SourceManager.instance.addListener(_onSourceChanged);
  }

  void _onSourceChanged() {
    if (!mounted) return;
    _loadHome();
  }

  @override
  void dispose() {
    SourceManager.instance.removeListener(_onSourceChanged);
    super.dispose();
  }

  /* -------------------------------------------------------------------------- */
  /*                               DATA LOAD                                    */
  /* -------------------------------------------------------------------------- */

  Future<void> _loadHome() async {
    try {
      final source = SourceManager.instance.activeSource;




      _sections = await source.getHomeFeed();
    } catch (_) {
      _sections = [];
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }


  /* -------------------------------------------------------------------------- */
  /*                               GREETING                                     */
  /* -------------------------------------------------------------------------- */

  String _greeting() {
    final hour = DateTime.now().hour;

    if (hour >= 6 && hour < 12) {
      return 'Good Morning!';
    } else if (hour >= 12 && hour < 18) {
      return 'Good Afternoon!';
    } else {
      return 'Good Evening!';
    }
  }

  /* -------------------------------------------------------------------------- */
  /*                                   UI                                       */
  /* -------------------------------------------------------------------------- */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,

        title: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Image.asset(
            'assets/images/rhythmax/transparent_fulltext.png',
            height: 35,
            fit: BoxFit.contain,
          ),
        ),

        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(
            height: 1,
            thickness: 0.6,
            color: Colors.white30,
          ),
        ),

        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                _greeting(),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),

      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
          padding: const EdgeInsets.only(bottom: 80),
          itemCount: _sections.length,
          itemBuilder: (context, index) {
            final section = _sections[index];
            return _section(section);
          },
        ),
      ),
    );
  }

  /* -------------------------------------------------------------------------- */
  /*                               SECTIONS                                     */
  /* -------------------------------------------------------------------------- */

  Widget _section(HomeSection section) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth * 0.42;
    final imageSize = cardWidth;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Text(
            section.title,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        SizedBox(
          height: imageSize + 72,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: section.items.length,
            itemBuilder: (context, index) {
              final item = section.items[index];
              return _card(item, cardWidth, imageSize);
            },
          ),
        ),
      ],
    );
  }


  /* -------------------------------------------------------------------------- */
  /*                                  CARD                                      */
  /* -------------------------------------------------------------------------- */

  Widget _card(HomeItem item, double cardWidth, double imageSize) {
    return GestureDetector(
      onTap: () {
        final shell = AppShellPage.of(context);

        switch (item.type) {
          case HomeItemType.album:
            shell.pushPage(AlbumPage(album: item.album!));
            break;

          case HomeItemType.playlist:
            shell.pushPage(PlaylistPage(playlist: item.playlist!));
            break;
        }
      },
      child: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: SizedBox(
          width: cardWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: FadeInImage(
                  placeholder:
                  const AssetImage('assets/images/placeholder.jpg'),
                  image: NetworkImage(item.artworkUrl ?? ''),
                  height: imageSize,
                  width: cardWidth,
                  fit: BoxFit.cover,
                  imageErrorBuilder: (_, __, ___) {
                    return Image.asset(
                      'assets/images/placeholder.jpg',
                      height: 170,
                      width: 170,
                      fit: BoxFit.cover,
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textScaler: const TextScaler.linear(1.0),
                    ),
                if (item.subtitle != null)
                  Text(
                    item.subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textScaler: const TextScaler.linear(1.0),
                    style: const TextStyle(
                      fontFamily: 'Poppins Medium',
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                 ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
