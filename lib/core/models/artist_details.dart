import 'artist.dart';
import 'track.dart';
import 'album.dart';

class ArtistDetails {
  final Artist artist;
  final List<Track> topTracks;
  final List<Album> albums;
  final List<Album> singles;

  ArtistDetails({
    required this.artist,
    required this.topTracks,
    required this.albums,
    required this.singles,
  });
}
