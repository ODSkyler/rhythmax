import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/track.dart';
import '../source/source_manager.dart';

/* -------------------------------------------------------------------------- */
/*                                   ENUMS                                    */
/* -------------------------------------------------------------------------- */

enum RepeatMode {
 off,
 all,
 one,
}


/* -------------------------------------------------------------------------- */
/*                              PLAYER CONTROLLER                             */
/* -------------------------------------------------------------------------- */

class PlayerController extends ChangeNotifier {
final AudioPlayer _player = AudioPlayer();

Future<int?> get androidAudioSessionId async {
  return _player.androidAudioSessionId;
 }

/* ---------------- QUEUE ---------------- */

final List<Track> _queue = [];
final List<Track> _originalQueue = [];

int _currentIndex = -1;

List<Track> get queue => List.unmodifiable(_queue);
int get currentIndex => _currentIndex;

Track? get currentTrack =>
(_currentIndex >= 0 && _currentIndex < _queue.length)
? _queue[_currentIndex]
    : null;

/* ---------------- STATE ---------------- */

String? _queueSourceId;
String? _queueSourceType;
String? get queueSourceId => _queueSourceId;
String? get queueSourceType => _queueSourceType;

  String? _playingFromType;   // album / playlist / search / queue
  String? _playingFromTitle;  // album name / playlist name

  String? get playingFromType => _playingFromType;
  String? get playingFromTitle => _playingFromTitle;

Duration position = Duration.zero;
Duration duration = Duration.zero;
Duration bufferedPosition = Duration.zero;

bool get isPlaying => _player.playing;

bool get isBuffering =>
  _player.processingState == ProcessingState.buffering;
bool get isLoading =>
  _player.processingState == ProcessingState.loading;
bool get shouldShowLoader {
  final state = _player.processingState;

  return state == ProcessingState.loading ||
         state == ProcessingState.buffering;
 }

bool shuffleEnabled = false;
RepeatMode repeatMode = RepeatMode.off;

bool _isExplicitBlocked(Track track) {
  final source = SourceManager.instance.activeSource;
  return track.isExplicit && !source.explicitEnabled;
 }

final Color backgroundColor = const Color(0xFF1C1D22);


/* ---------------- QUALITY LABEL ---------------- */

String _currentQualityLabel = 'Normal (96 kbps)';
String get currentQualityLabel => _currentQualityLabel;

void setQualityLabel(String label) {
  _currentQualityLabel = label;
  _preloadedNextSource = null;
  _preloadedNextIndex = null;
  notifyListeners();
 }

/* ---------------- PREF KEYS ---------------- */

static const _prefShuffle = 'player_shuffle';
static const _prefRepeat = 'player_repeat';
static const _prefGapless = 'player_gapless';
static const Duration _preloadThreshold = Duration(seconds: 15);
bool gaplessEnabled = true;

  AudioSource? _preloadedNextSource;
  int? _preloadedNextIndex;
  bool _isPreloadingNext = false;

/* ---------------- INIT ---------------- */

PlayerController() {
_restorePrefs();

_player.positionStream.listen((p) {
   position = p;
   _checkAndPreloadNext();
   notifyListeners();
 });

_player.bufferedPositionStream.listen((buffered) {
  bufferedPosition = buffered;
  notifyListeners();
});

_player.durationStream.listen((d) {
  if (d != null) {
  duration = d;
  notifyListeners();
  }
});

// ✅ THIS IS THE FIX THAT MAKES UI AUTO UPDATE
  _player.currentIndexStream.listen((index) {
    if (index == null) return;

    _currentIndex = index;

    // reset preload for upcoming track
    _preloadedNextSource = null;
    _preloadedNextIndex = null;

    notifyListeners();
  });


_player.playerStateStream.listen((_) {
   notifyListeners();
});
}

  Future<void> _checkAndPreloadNext() async {
    if (!gaplessEnabled) return;
    if (_queue.isEmpty) return;
    if (_currentIndex < 0) return;
    if (_isPreloadingNext) return;

    final remaining = duration - position;

    if (remaining > _preloadThreshold) return;

    final nextIndex = await _findNextPlayableIndex();
    if (nextIndex == null) return;

    if (_preloadedNextIndex == nextIndex) return;

    _isPreloadingNext = true;

    try {
      final source = SourceManager.instance.activeSource;
      final track = _queue[nextIndex];

      final uri = await source.getStreamUrl(track);

      _preloadedNextSource = AudioSource.uri(uri);
      _preloadedNextIndex = nextIndex;
    } catch (_) {}

    _isPreloadingNext = false;
  }

  Future<int?> _findNextPlayableIndex() async {
    if (_queue.isEmpty) return null;

    int i = _currentIndex + 1;

    while (true) {
      if (i >= _queue.length) {
        if (repeatMode == RepeatMode.all) {
          i = 0;
        } else {
          return null;
        }
      }

      if (!_isExplicitBlocked(_queue[i])) return i;

      i++;
    }
  }


/* -------------------------------------------------------------------------- */
/*                                 PLAYBACK                                   */
/* -------------------------------------------------------------------------- */

Future<void> playTrack(
 Track track, {
 List<Track>? queue,
      String? sourceId,
      String? sourceType,
      String? playType,
      String? sourceTitle,
}) async {
  _queueSourceId = sourceId;
  _queueSourceType = sourceType;
  _playingFromType = playType;
  _playingFromTitle = sourceTitle;
  _queue.clear();
  _originalQueue.clear();

final inputQueue =
  (queue != null && queue.isNotEmpty) ? queue : [track];

final playableQueue =
  inputQueue.where((t) => !_isExplicitBlocked(t)).toList();

if (playableQueue.isEmpty) return;

_queue.addAll(playableQueue);
_originalQueue.addAll(playableQueue);

final startTrack =
  playableQueue.contains(track) ? track : playableQueue.first;

_currentIndex = _queue.indexOf(startTrack);

final source = SourceManager.instance.activeSource;

final audioSources = <AudioSource>[];

for (final t in _queue) {
final uri = await source.getStreamUrl(t);
audioSources.add(AudioSource.uri(uri));
}

await _player.setAudioSources(
audioSources,
initialIndex: _currentIndex,
preload: false,
);

if (shuffleEnabled) {
await _player.setShuffleModeEnabled(true);
await _player.shuffle();
}

await _player.play();

notifyListeners();
}

Future<void> playAt(int index) async {
if (index < 0 || index >= _queue.length) return;
_currentIndex = index;
await _player.seek(Duration.zero, index: index);
notifyListeners();
}

/* -------------------------------------------------------------------------- */
/*                                  CONTROLS                                  */
/* -------------------------------------------------------------------------- */

Future<void> play() async {
  if (!_player.playing) await _player.play();
 }

Future<void> pause() async {
  if (_player.playing) await _player.pause();
 }

Future<void> stop() async {
 try {
  await _player.stop();
  } catch (_) {}
 }

Future<void> next() async {
  if (_preloadedNextIndex != null) {
    await _player.setAudioSource(
      _preloadedNextSource!,
      initialIndex: 0,
    );

    _currentIndex = _preloadedNextIndex!;

    _preloadedNextSource = null;
    _preloadedNextIndex = null;

    await _player.play();
    return;
  }

  if (shuffleEnabled) {
    final nextIndex = _player.nextIndex;
    if (nextIndex == null) return;

    await _player.seek(Duration.zero, index: nextIndex);
    return;
  }



  if (_queue.isEmpty) return;

int i = _currentIndex + 1;

while (true) {
  if (i >= _queue.length) {
  if (repeatMode == RepeatMode.all) {
    i = 0;
  } else {
    return;
  }
}

if (!_isExplicitBlocked(_queue[i])) {
 await _player.seek(Duration.zero, index: i);
return;
   }
  i++;
  }
}

Future<void> previous() async {
  if (shuffleEnabled) {
    final prevIndex = _player.previousIndex;

    if (prevIndex == null) return;

    await _player.seek(Duration.zero, index: prevIndex);

    return;
  }


if (_queue.isEmpty) return;

int i = _currentIndex - 1;

while (i >= 0 && _isExplicitBlocked(_queue[i])) {
i--;
}

if (i < 0) return;

await _player.seek(Duration.zero, index: i);
}

Future<void> seek(Duration value) async {
await _player.seek(value);
}



/* -------------------------------------------------------------------------- */
/*                             QUEUE MODIFICATION                             */
/* -------------------------------------------------------------------------- */

  void removeFromQueue(int index) {
    if (index < 0 || index >= _queue.length) return;

    _queue.removeAt(index);
    _originalQueue.removeAt(index);

    _player.removeAudioSourceAt(index);
    notifyListeners();
  }

  void clearQueue() {
    _queue.clear();
    _originalQueue.clear();
    _currentIndex = -1;

    _queueSourceId = null;
    _queueSourceType = null;

    _player.clearAudioSources();
    _player.stop();
    notifyListeners();
  }


  void moveQueueItem(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _queue.length) return;
    if (newIndex < 0 || newIndex >= _queue.length) return;

    if (newIndex > oldIndex) newIndex--;

    final track = _queue.removeAt(oldIndex);
    _queue.insert(newIndex, track);

    _player.moveAudioSource(oldIndex, newIndex);
    notifyListeners();
  }

  // ADD TO QUEUE
  Future<void> addToQueue(Track track) async {
    final wasEmpty = _queue.isEmpty;

    _queue.add(track);
    _originalQueue.add(track);

    final source = SourceManager.instance.activeSource;
    final uri = await source.getStreamUrl(track);

    await _player.addAudioSource(AudioSource.uri(uri));

    // ⭐ AUTO PLAY IF QUEUE WAS EMPTY
    if (wasEmpty) {
      _queueSourceId = 'queue';
      _queueSourceType = 'queue';
      _playingFromType = 'QUEUE';
      _playingFromTitle = 'Custom queue';
      _currentIndex = 0;
      await _player.seek(Duration.zero, index: 0);
      await _player.play();
    }

    notifyListeners();
  }

  bool isTrackInQueue(String trackId) {
    return _queue.any((t) => t.id == trackId);
  }

  Future<void> removeTrackById(String trackId) async {
    final index = _queue.indexWhere((t) => t.id == trackId);
    if (index == -1) return;

    _queue.removeAt(index);
    _originalQueue.removeAt(index);

    await _player.removeAudioSourceAt(index);

    if (_currentIndex >= _queue.length) {
      _currentIndex = _queue.length - 1;
    }

    notifyListeners();
  }

/* -------------------------------------------------------------------------- */
/*                                REBUILD                                     */
/* -------------------------------------------------------------------------- */

  Future<void> _rebuildAudioPlaylist({
    bool keepIndex = true,
    bool keepPosition = true,
    bool autoPlay = true,
  }) async {
    if (_queue.isEmpty) return;

    final source = SourceManager.instance.activeSource;

    final currentTrackBefore = currentTrack;
    final currentPositionBefore = position;
    final wasPlaying = isPlaying;

    final audioSources = <AudioSource>[];

    for (final t in _queue) {
      final uri = await source.getStreamUrl(t);
      audioSources.add(AudioSource.uri(uri));
    }

    int newIndex = 0;

    if (keepIndex && currentTrackBefore != null) {
      final idx = _queue.indexWhere((t) => t.id == currentTrackBefore.id);
      if (idx != -1) newIndex = idx;
    }

    await _player.setAudioSources(
      audioSources,
      initialIndex: newIndex,
      initialPosition: keepPosition ? currentPositionBefore : Duration.zero,
      preload: gaplessEnabled,
    );

    if (shuffleEnabled) {
      await _player.setShuffleModeEnabled(true);
      await _player.shuffle();
    }

    if (autoPlay && wasPlaying) {
      await _player.play();
    }
  }

  Future<void> rebuildQueueWithNewQuality() async {
    if (_queue.isEmpty) return;

    final currentTrack = this.currentTrack;
    final currentPos = position;

    if (currentTrack == null) return;

    final source = SourceManager.instance.activeSource;

    final newSources = <AudioSource>[];

    for (final track in _queue) {
      final uri = await source.getStreamUrl(track);
      newSources.add(AudioSource.uri(uri));
    }

    await _player.setAudioSources(
      newSources,
      initialIndex: _currentIndex,
      initialPosition: currentPos,
      preload: gaplessEnabled,
    );

    if (shuffleEnabled) {
      await _player.setShuffleModeEnabled(true);
      await _player.shuffle();
    }

    await _player.play();
  }



/* -------------------------------------------------------------------------- */
/*                                SHUFFLE                                     */
/* -------------------------------------------------------------------------- */

Future<void> toggleShuffle() async {
shuffleEnabled = !shuffleEnabled;

await _player.setShuffleModeEnabled(shuffleEnabled);

if (shuffleEnabled && _queue.isNotEmpty) {
await _player.shuffle();
}

final prefs = await SharedPreferences.getInstance();
await prefs.setBool(_prefShuffle, shuffleEnabled);

notifyListeners();
}

/* -------------------------------------------------------------------------- */
/*                                HELPERS                                     */
/* -------------------------------------------------------------------------- */

  void playFromCurrentQueue(Track track) {
    final index = _queue.indexWhere((t) => t.id == track.id);
    if (index != -1) {
      playAt(index);
    }
  }

/* -------------------------------------------------------------------------- */
/*                                 REPEAT                                     */
/* -------------------------------------------------------------------------- */

Future<void> toggleRepeatMode() async {
switch (repeatMode) {
case RepeatMode.off:
repeatMode = RepeatMode.all;
await _player.setLoopMode(LoopMode.all);
break;

case RepeatMode.all:
repeatMode = RepeatMode.one;
await _player.setLoopMode(LoopMode.one);
break;

case RepeatMode.one:
repeatMode = RepeatMode.off;
await _player.setLoopMode(LoopMode.off);
break;
}

final prefs = await SharedPreferences.getInstance();
await prefs.setInt(_prefRepeat, repeatMode.index);

notifyListeners();
}

/* -------------------------------------------------------------------------- */
/*                               GAPLESS                                      */
/* -------------------------------------------------------------------------- */

  Future<void> toggleGapless(bool value) async {
    gaplessEnabled = value;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefGapless, value);

    await _rebuildAudioPlaylist();

    notifyListeners();
  }


/* -------------------------------------------------------------------------- */
/*                               RESTORE PREFS                                */
/* -------------------------------------------------------------------------- */

Future<void> _restorePrefs() async {
final prefs = await SharedPreferences.getInstance();

shuffleEnabled = prefs.getBool(_prefShuffle) ?? false;
gaplessEnabled = prefs.getBool(_prefGapless) ?? true;

final repeatIndex = prefs.getInt(_prefRepeat);
if (repeatIndex != null &&
repeatIndex >= 0 &&
repeatIndex < RepeatMode.values.length) {
repeatMode = RepeatMode.values[repeatIndex];
}

// 🔧 sync repeat with audio engine
switch (repeatMode) {
   case RepeatMode.off:
   await _player.setLoopMode(LoopMode.off);
   break;
   case RepeatMode.all:
await _player.setLoopMode(LoopMode.all);
    break;
    case RepeatMode.one:
    await _player.setLoopMode(LoopMode.one);
    break;
  }
await _player.setShuffleModeEnabled(shuffleEnabled);
  if (shuffleEnabled) {
     await _player.shuffle();
  }
}


/* -------------------------------------------------------------------------- */
/*                                   CLEANUP                                  */
/* -------------------------------------------------------------------------- */

@override
void dispose() {
  _player.dispose();
   super.dispose();
  }
}

