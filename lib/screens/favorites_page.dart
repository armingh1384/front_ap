import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_ap/services/SocketService.dart';
import 'package:flutter_ap/screens/MusicPlayer.dart';

class FavoritesPage extends StatefulWidget {
  final String username;
  final SocketService socketService;

  const FavoritesPage({
    Key? key,
    required this.username,
    required this.socketService,
  }) : super(key: key);

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  List<Map<String, dynamic>> favoriteSongs = [];
  bool _isLoading = true;
  int? currentlyPlayingIndex;

  @override
  void initState() {
    super.initState();
    widget.socketService.setOnMessage(_handleServerMessage);
    _requestFavoriteSongs();
  }

  void _requestFavoriteSongs() {
    final message = {
      "requestType": "user",
      "action": "getFavoriteSongs",
      "data": {
        "username": widget.username
      }
    };
    widget.socketService.sendMessage(message);
  }

  void _handleServerMessage(String message) {
    try {
      final Map<String, dynamic> response = jsonDecode(message.trim());

      if (response['status'] == 'success' && response['data'] != null) {
        final data = response['data'] as Map<String, dynamic>;

        if (data.containsKey('favoriteSongs')) {
          final List<dynamic> receivedSongs = data['favoriteSongs'] as List;
          List<Map<String, dynamic>> newFavoriteSongs = [];

          for (var songData in receivedSongs) {
            newFavoriteSongs.add({
              "id": songData['id']?.toString() ?? UniqueKey().toString(),
              "title": songData['name']?.toString() ?? 'Unknown',
              "artist": songData['artist']?.toString() ?? 'Unknown',
              "base64Audio": songData['base64Audio']?.toString() ?? '',
              "genre": songData['genre']?.toString() ?? 'POP',
              "countoflikes": songData['countoflikes'] ?? 0,
              "isLiked": true,
              "album": songData['album']?.toString() ?? '',
              "releaseYear": songData['releaseYear'] ?? 2023,
              "playlistName": songData['playlistName']?.toString() ?? 'Unknown Playlist',
            });
          }

          setState(() {
            favoriteSongs = newFavoriteSongs;
            _isLoading = false;
          });
          return;
        }
      }

      _getFavoritesFromAllPlaylists();
    } catch (e) {
      _getFavoritesFromAllPlaylists();
    }
  }

  void _getFavoritesFromAllPlaylists() {
    final message = {
      "requestType": "user",
      "action": "getPlaylists",
      "data": {
        "username": widget.username
      }
    };
    widget.socketService.sendMessage(message);
  }

  void _processPlaylistsForFavorites(Map<String, dynamic> response) {
    if (response['status'] == 'success' && response['data'] != null) {
      final data = response['data'] as Map<String, dynamic>;

      if (data.containsKey('playlists')) {
        final List<dynamic> receivedPlaylists = data['playlists'] as List;
        List<Map<String, dynamic>> newFavoriteSongs = [];

        for (var playlistData in receivedPlaylists) {
          final String playlistName = playlistData['playlistname']?.toString() ?? "Unknown Playlist";

          if (playlistData.containsKey('songs')) {
            for (var song in playlistData['songs'] as List) {
              if (song is Map) {
                final songMap = song as Map<String, dynamic>;
                if (songMap['isLiked'] == true) {
                  newFavoriteSongs.add({
                    "id": songMap['id']?.toString() ?? UniqueKey().toString(),
                    "title": songMap['name']?.toString() ?? 'Unknown',
                    "artist": songMap['artist']?.toString() ?? 'Unknown',
                    "base64Audio": songMap['base64Audio']?.toString() ?? '',
                    "genre": songMap['genre']?.toString() ?? 'POP',
                    "countoflikes": songMap['countoflikes'] ?? 0,
                    "isLiked": true,
                    "album": songMap['album']?.toString() ?? '',
                    "releaseYear": songMap['releaseYear'] ?? 2023,
                    "playlistName": playlistName,
                  });
                }
              }
            }
          }
        }

        setState(() {
          favoriteSongs = newFavoriteSongs;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleLikeSong(Map<String, dynamic> song) async {
    setState(() {
      favoriteSongs.removeWhere((s) => s['id'] == song['id']);
    });

    final message = {
      "requestType": "user",
      "action": "likeSong",
      "data": {
        "username": widget.username,
        "playlistname": song['playlistName'],
        "songname": song['title'],
        "isLiked": false,
      }
    };

    widget.socketService.sendMessage(message);
  }

  Widget _buildImageWidget() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.music_note, color: Colors.white70),
    );
  }

  void _playSong(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MusicPlayerPage(
          playlist: favoriteSongs,
          initialIndex: index,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Favorite Songs'),
        backgroundColor: Colors.purple[900],
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _requestFavoriteSongs,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.purple))
          : favoriteSongs.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite_border, size: 50, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No favorite songs yet',
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Like songs in your playlists to see them here',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: favoriteSongs.length,
        itemBuilder: (context, index) {
          final song = favoriteSongs[index];
          final isLiked = song['isLiked'] ?? false;

          return Card(
            color: Colors.grey[900],
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              leading: _buildImageWidget(),
              title: Text(
                song["title"] as String,
                style: const TextStyle(color: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${song["artist"] as String} • ${song["album"] ?? "No Album"}',
                    style: const TextStyle(color: Colors.white70),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'From: ${song["playlistName"]}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.favorite,
                      color: isLiked ? Colors.red : Colors.white70,
                    ),
                    onPressed: () => _toggleLikeSong(song),
                    iconSize: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    song['countoflikes']?.toString() ?? '0',
                    style: TextStyle(
                      color: isLiked ? Colors.red : Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              onTap: () => _playSong(index),
            ),
          );
        },
      ),
    );
  }
}