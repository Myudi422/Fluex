// playlist_service.dart

import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class PlaylistService {
  static Future<Playlist> getPlaylistById(String playlistId) async {
    try {
      final yt = YoutubeExplode();
      final playlist = await yt.playlists.get(playlistId);
      yt.close();
      return playlist;
    } catch (e) {
      print("Error fetching playlist by ID: $e");
      throw Exception("Failed to fetch playlist");
    }
  }
}
