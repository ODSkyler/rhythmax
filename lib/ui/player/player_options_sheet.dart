import 'package:flutter/material.dart';
import 'package:rhythmax/core/models/track.dart';
import 'package:rhythmax/core/models/album.dart';
import 'package:rhythmax/core/models/artist.dart';
import 'package:rhythmax/ui/album/album_page.dart';
import 'package:rhythmax/ui/artist/artist_page.dart';
import 'package:rhythmax/ui/app_shell_page.dart';

class PlayerOptionsSheet extends StatelessWidget {
  final Track track;
  final AppShellController shell;

  const PlayerOptionsSheet({
    super.key,
    required this.track,
    required this.shell,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: Color(0xFF1C1D22),
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _handle(),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: FadeInImage(
                    placeholder: const AssetImage('assets/images/album_placeholder.jpg'),
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
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (track.isExplicit)
                            Padding(
                              padding: const EdgeInsets.only(right: 3),
                              child: const Icon(
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
                              style: const TextStyle(
                                fontFamily: 'Poppins Medium',
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(color: Colors.white24),

          _option(
            icon: Icons.album,
            title: 'View album',
            onTap: () => _openAlbum(context),
          ),

          _option(
            icon: Icons.person,
            title: 'View artist',
            onTap: () => _openArtist(context),
          ),
        ],
      ),

    );
  }

  Widget _handle() {
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white30,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _option({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
    );
  }

  /* -------------------------------------------------------------------------- */
  /*                               NAVIGATION                                   */
  /* -------------------------------------------------------------------------- */

  Future<void> _openAlbum(BuildContext context) async {
    final albumId = track.albumId;
    if (albumId == null || albumId.isEmpty) return;

    Navigator.pop(context); // close options sheet

    shell.popPage(); // remove FullPlayerPage from overlay stack

    shell.pushPage(
      AlbumPage(
        album: Album(
          id: albumId,
          source: track.source,
          title: track.album ?? 'Album',
          artists: track.artists,
          artworkUrl: track.artworkUrl,
          tracks: const [], // EMPTY → AlbumPage will auto fetch full album
        ),
      ),
    );
  }


  Future<void> _openArtist(BuildContext context) async {
    final ids = track.artistIds;
    if (ids.isEmpty) return;

    Navigator.pop(context); // close options sheet

    // 🎯 open instantly (no API wait here anymore)

    if (ids.length == 1) {
      shell.popPage(); // remove player page

      shell.pushPage(
        ArtistDetailsPage(
          artist: Artist(
            id: ids.first,
            source: track.source,
            name: track.artists.first,
            artworkUrl: null, // loads later inside artist page
          ),
        ),
      );
      return;
    }

    _showArtistChooser();
  }


  /* -------------------------------------------------------------------------- */
  /*                           ARTIST SELECTOR                                   */
  /* -------------------------------------------------------------------------- */

  void _showArtistChooser() {
    showModalBottomSheet(
      context: shell.context,
      backgroundColor: const Color(0xFF1C1D22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) {
        return ListView.builder(
          shrinkWrap: true,
          itemCount: track.artists.length,
          itemBuilder: (_, i) {
            return ListTile(
              title: Text(track.artists[i]),
              onTap: () {
                Navigator.pop(shell.context);

                shell.popPage(); // remove player

                shell.pushPage(
                  ArtistDetailsPage(
                    artist: Artist(
                      id: track.artistIds[i],
                      source: track.source,
                      name: track.artists[i],
                      artworkUrl: null,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
