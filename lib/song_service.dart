import 'dart:convert';

class SongService {
  final SocketService socketService;

  SongService({required this.socketService});

  Future<List<Song>> fetchSongs() async {
    final completer = Completer<List<Song>>();

    socketService.setOnMessage((message) {
      final response = jsonDecode(message);

      if (response['status'] == 'success' && response['data'] != null) {
      
        final songsJson = response['data']['songs'] as List<dynamic>;
        final songs = songsJson.map((json) => Song.fromJson(json)).toList();
        completer.complete(songs);
      } else {
        completer.completeError('Failed to fetch songs: ${response['message']}');
      }
    });

     
    socketService.sendMessage({
      'requestType': 'song',
      'action': 'getAllSongs', 
      'data': {},
    });

    return completer.future;
  }
}
