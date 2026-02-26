import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:rhythmax/core/player/player_provider.dart';
import 'package:rhythmax/core/models/track.dart';
import 'package:rhythmax/core/player/player_controller.dart';

class RhythmaxAudioHandler extends BaseAudioHandler {
  final _controller = globalPlayer;

  static const _shuffleId = 'shuffle';
  static const _repeatId = 'repeat';

  String _shuffleIcon() =>
      _controller.shuffleEnabled
          ? 'drawable/ic_shuffle_on'
          : 'drawable/ic_shuffle';

  String _repeatIcon() {
    switch (_controller.repeatMode) {
      case RepeatMode.off:
        return 'drawable/ic_repeat';
      case RepeatMode.all:
        return 'drawable/ic_repeat_on';
      case RepeatMode.one:
        return 'drawable/ic_repeat_one';
    }
  }

  StreamSubscription? _playerStateSub;
  StreamSubscription? _positionSub;
  StreamSubscription? _indexSub;

  RhythmaxAudioHandler() {
    _playerStateSub =
        _controller.player.playerStateStream.listen((_) => _syncState());

    _positionSub =
        _controller.player.positionStream.listen((_) => _syncState());

    _indexSub =
        _controller.player.currentIndexStream.listen((_) => _syncState());

    _syncState();
  }

  /* -------------------------------------------------------------------------- */
  /*                                  MEDIA ITEM                                */
  /* -------------------------------------------------------------------------- */

  MediaItem _mapTrack(Track t) => MediaItem(
    id: t.id,
    title: t.title,
    artist: t.artists.join(', '),
    album: t.album,
    duration: t.duration,
    artUri: t.artworkUrl != null ? Uri.parse(t.artworkUrl!) : null,
  );

  /* -------------------------------------------------------------------------- */
  /*                                 STATE SYNC                                 */
  /* -------------------------------------------------------------------------- */

  void _syncState() {
    final track = _controller.currentTrack;

    /// update metadata only when track changes
    if (track != null && mediaItem.value?.id != track.id) {
      mediaItem.add(_mapTrack(track));
    }

    playbackState.add(
      PlaybackState(
        controls: [
          /// 🔀 SHUFFLE
          MediaControl.custom(
            androidIcon: _shuffleIcon(),
            label: 'Shuffle',
            name: _shuffleId,
          ),

          /// ⏮ PREV
          MediaControl.skipToPrevious,

          /// ⏯ PLAY / PAUSE
          _controller.isPlaying
              ? MediaControl.pause
              : MediaControl.play,

          /// ⏭ NEXT
          MediaControl.skipToNext,

          /// 🔁 REPEAT
          MediaControl.custom(
            androidIcon: _repeatIcon(),
            label: 'Repeat',
            name: _repeatId,
          ),
        ],

        /// seekbar + system transport controls
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
          MediaAction.skipToNext,
          MediaAction.skipToPrevious,
        },

        /// compact layout → only prev / play / next
        androidCompactActionIndices: const [1, 2, 3],

        processingState: _mapProcessingState(),
        playing: _controller.isPlaying,
        updatePosition: _controller.position,
        bufferedPosition: _controller.bufferedPosition,
        queueIndex: _controller.currentIndex,
        speed: 1.0,
      ),
    );
  }

  AudioProcessingState _mapProcessingState() {
    if (_controller.isLoading) return AudioProcessingState.loading;
    if (_controller.isBuffering) return AudioProcessingState.buffering;
    return AudioProcessingState.ready;
  }

  /* -------------------------------------------------------------------------- */
  /*                                   CONTROLS                                 */
  /* -------------------------------------------------------------------------- */

  @override
  Future<void> play() => _controller.play();

  @override
  Future<void> pause() => _controller.pause();

  @override
  Future<void> seek(Duration position) =>
      _controller.seek(position);

  @override
  Future<void> skipToNext() => _controller.next();

  @override
  Future<void> skipToPrevious() =>
      _controller.previous();

  @override
  Future<void> stop() => _controller.stop();

  /* -------------------------------------------------------------------------- */
  /*                              CUSTOM ACTIONS                                */
  /* -------------------------------------------------------------------------- */

  @override
  Future<void> customAction(String name,
      [Map<String, dynamic>? extras]) async {
    switch (name) {
      case _shuffleId:
        await _controller.toggleShuffle();
        break;

      case _repeatId:
        await _controller.toggleRepeatMode();
        break;
    }

    _syncState();
  }
}