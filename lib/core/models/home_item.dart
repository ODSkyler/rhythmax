import 'album.dart';
import 'playlist.dart';

enum HomeItemType {
  album,
  playlist,
}

class HomeItem {
  final HomeItemType type;
  final Album? album;
  final Playlist? playlist;

  HomeItem._({
    required this.type,
    this.album,
    this.playlist,
  });

  factory HomeItem.album(Album album) {
    return HomeItem._(
      type: HomeItemType.album,
      album: album,
    );
  }

  factory HomeItem.playlist(Playlist playlist) {
    return HomeItem._(
      type: HomeItemType.playlist,
      playlist: playlist,
    );
  }

  String get title =>
      album?.title ??
          playlist?.title ??
          '';

  String? get subtitle =>
      album?.artists.join(', ') ??
          playlist?.description;

  String? get artworkUrl =>
      album?.artworkUrl ??
          playlist?.artworkUrl;
}
