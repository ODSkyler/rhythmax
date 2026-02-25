import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:rhythmax/core/player/player_provider.dart';
import 'package:rhythmax/core/source/source_manager.dart';

class QueueBottomSheet extends StatelessWidget {
  const QueueBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        globalPlayer,
        SourceManager.instance,
      ]),
      builder: (_, __) {
        final queue = globalPlayer.queue;
        final current = globalPlayer.currentIndex;
        final shuffle = globalPlayer.shuffleEnabled;
        final source = SourceManager.instance.activeSource;
        final trackCount = queue.length;
        final trackLabel = trackCount == 1
            ? '1 track in queue'
            : '$trackCount tracks in queue';

        return FractionallySizedBox(
          heightFactor: .70,
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF1C1D22),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: ClipRRect(
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 12),

                    // Drag handle
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white30,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Player queue',
                                  style: TextStyle(
                                    fontSize: 25,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  trackLabel,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.white54,
                                    fontFamily: 'Poppins Medium',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.shuffle,
                              color: shuffle ? Colors.cyanAccent : Colors.grey,
                            ),
                            onPressed: globalPlayer.toggleShuffle,
                          ),
                          IconButton(
                            icon: const Icon(Icons.clear_all),
                            onPressed: () async {
                              final parentContext = context;

                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (dialogContext) => AlertDialog(
                                  title: const Text('Clear queue?'),
                                  content: const Text(
                                    'This will clear the queue and stop playback.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(dialogContext, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(dialogContext, true),
                                      child: const Text('Clear'),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                globalPlayer.clearQueue();

                                if (parentContext.mounted) {
                                  Navigator.pop(parentContext);
                                }
                              }
                            },
                          ),
                        ],
                      ),

                    ),

                    const SizedBox(height: 8),

                    // Queue list
                    Expanded(
                      child: queue.isEmpty
                          ? const Center(
                        child: Text(
                          'Queue is empty',
                          style:
                          TextStyle(color: Colors.white70),
                        ),
                      )
                          : ReorderableListView.builder(
                        itemCount: queue.length,
                        buildDefaultDragHandles: false,
                        onReorder: (oldIndex, newIndex) {
                          if (!shuffle) {
                            globalPlayer.moveQueueItem(
                                oldIndex, newIndex);
                          }
                        },
                        itemBuilder: (_, index) {
                          final track = queue[index];
                          final isCurrent = index == current;
                          final explicitBlocked =
                              track.isExplicit && !source.explicitEnabled;

                          return ListTile(
                            key: ValueKey(track.id),
                            leading: _artwork(
                                track.artworkUrl),
                            title: Text(
                              track.title,
                              maxLines: 1,
                              overflow:
                              TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight:
                                FontWeight.w800,
                                color: isCurrent
                                    ? Colors.cyanAccent
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
                                      size: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                Expanded(
                                  child: Text(
                                    track.artists
                                        .join(', '),
                                    maxLines: 1,
                                    overflow:
                                    TextOverflow
                                        .ellipsis,
                                    style:
                                    const TextStyle(
                                      fontFamily: 'Poppins Medium',
                                      fontSize: 12,
                                      color: Colors
                                          .white70,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize:
                              MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                      Icons.close,
                                      size: 18),
                                  onPressed: () =>
                                      globalPlayer
                                          .removeFromQueue(
                                          index),
                                ),
                                if (!shuffle)
                                  ReorderableDragStartListener(
                                    index: index,
                                    child: const Icon(
                                      Icons.drag_handle,
                                      color:
                                      Colors.white54,
                                    ),
                                  ),
                              ],
                            ),
                            onTap: () {
                              if (explicitBlocked) {
                                _showExplicitBlockedDialog(context);
                                return;
                              }
                              globalPlayer.playAt(index);
                            },

                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _artwork(String? url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: FadeInImage(
        placeholder:
        const AssetImage('assets/images/music_placeholder.jpg'),
        image: NetworkImage(url ?? ''),
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        imageErrorBuilder: (_, __, ___) => Image.asset(
          'assets/images/music_placeholder.jpg',
          width: 48,
          height: 48,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  void _showExplicitBlockedDialog(BuildContext context) {
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
