import 'dart:convert';
import 'package:flutter_ap/models/playlist.dart';
import 'SocketService.dart';

class PlaylistService {
  final SocketService socket;

  PlaylistService(this.socket);

  void getPlaylists(Function(List<Playlist>) onResult) {
    socket.setOnMessage((response) {
      final data = jsonDecode(response);
      if (data['action'] == 'getPlaylists') {
        List<Playlist> playlists = (data['playlists'] as List)
            .map((e) => Playlist.fromJson(e))
            .toList();
        onResult(playlists);
      }
    });

    socket.sendMessage({'action': 'getPlaylists'});
  }

  void createPlaylist(String name) {
    socket.sendMessage({'action': 'createPlaylist', 'name': name});
  }

  void addSongToPlaylist(String playlistId, String songId) {
    socket.sendMessage({
      'action': 'addSongToPlaylist',
      'playlistId': playlistId,
      'songId': songId,
    });
  }

  void deletePlaylist(String playlistId) {
    socket.sendMessage({'action': 'deletePlaylist', 'playlistId': playlistId});
  }
}
