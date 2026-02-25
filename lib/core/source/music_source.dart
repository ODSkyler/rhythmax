import '../models/track.dart';
import '../models/album.dart';
import '../models/artist.dart';
import '../models/playlist.dart';
import '../models/artist_details.dart';
import '../models/home_section.dart';
import 'package:rhythmax/ui/settings/source_settings.dart';

abstract class MusicSource {
  /// Unique id: YT Music, JioSaavn, TIDAL, Local, etc.
  String get id;

  /// Human readable name
  String get name;
  String get tags;

  SourceSettings? get settings => null;

  /* ---------------- SEARCH ---------------- */

  Future<List<Track>> searchTracks(String query);
  Future<List<Album>> searchAlbums(String query);
  Future<List<Artist>> searchArtists(String query);
  Future<List<Playlist>> searchPlaylists(String query);

  /* ---------------- HOME FEED ---------------- */

  /// Optional: Home feed (sections like Trending, Charts, etc.)
  /// Sources that support home feed MUST override this.
  Future<List<HomeSection>> getHomeFeed() {
    throw UnimplementedError(
      'Home feed not supported by this source',
    );
  }

  /* ---------------- FETCH ---------------- */

  Future<Album> getAlbum(String albumId);
  Future<Artist> getArtist(String artistId);
  Future<Playlist> getPlaylist(String playlistId);

  /// Optional: Extended artist details
  Future<ArtistDetails> getArtistDetails(String artistId) {
    throw UnimplementedError(
      'Artist details not supported by this source',
    );
  }

  /* ---------------- STREAM ---------------- */

  /// Must return a DIRECT playable URL
  /// Core/player doesn't care how it was produced
  Future<Uri> getStreamUrl(
      Track track, {
        AudioQuality quality = AudioQuality.high,
      });

  /* ---------------- OPTIONAL ---------------- */

  /// Lyrics (plain or synced, source decides)
  Future<String?> getLyrics(Track track) async => null;

  /// Music video (only for sources that support it)
  Future<Uri?> getMusicVideoUrl(Track track) async => null;

  /*------------ EXPLICIT CONTENT ------------- */
  /// Wheather explicit content is allowed for this source
  /// Default = true (sources can override)
  bool get explicitEnabled => true;
  Future<void> setExplicitEnabled(bool enabled) async{}

  /* ---------------- LIBRARY PREP ---------------- */

  Future<Map<String, dynamic>?> prepareTrackForLibrary(Track track) async {
    return null;
  }

}
