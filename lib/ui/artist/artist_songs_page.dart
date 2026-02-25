import 'package:flutter/material.dart';
import 'package:rhythmax/core/models/artist.dart';
import 'package:rhythmax/core/models/track.dart';
import 'package:rhythmax/core/player/player_provider.dart';
import 'package:rhythmax/core/source/source_manager.dart';
import 'package:rhythmax/ui/widget/track_options_sheet.dart';
import '../app_shell_page.dart';

class ArtistSongsPage extends StatelessWidget {
  final Artist artist;
  final List<Track> tracks;

  const ArtistSongsPage({
    super.key,
    required this.artist,
    required this.tracks,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            _appBar(context),
            Expanded(child: _trackList()),
          ],
        ),
      ),
    );
  }

  /* ---------------- APP BAR ---------------- */

  Widget _appBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => AppShellPage.of(context).popPage(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${artist.name} • Popular tracks',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /* ---------------- TRACK LIST (REALTIME) ---------------- */

  Widget _trackList() {
    if (tracks.isEmpty) {
      return const Center(
        child: Text(
          'No songs found',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: tracks.length,
      itemBuilder: (context, index) {
        final track = tracks[index];

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
                  horizontal: 16, vertical: 0),
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
                  fontWeight:
                  isCurrent ? FontWeight.w700 : FontWeight.w600,
                  color: isCurrent
                      ? Theme.of(context).colorScheme.primary
                      : explicitBlocked
                      ? Colors.white30
                      : Colors.white,
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
                        color: Colors.white70,
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

                globalPlayer.playTrack(
                  track,
                  queue: tracks,
                  sourceId: artist.id,
                  sourceType: 'artist',
                  playType: 'THE ARTIST',
                  sourceTitle: artist.name,
                );
              },
            );
          },
        );
      },
    );
  }

  void _showExplicitBlockedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Explicit Content'),
        content: const Text(
          'Enable Explicit Content in the active source settings.',
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
}
