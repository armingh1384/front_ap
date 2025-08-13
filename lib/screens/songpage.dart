import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ap/screens/MusicPlayer.dart';
import 'package:flutter_ap/services/SocketService.dart';

class SongsPage extends StatefulWidget {
  final String username;
  final SocketService socketService;

  const SongsPage({Key? key, required this.username, required this.socketService}) : super(key: key);

  @override
  State<SongsPage> createState() => _SongsPageState();
}

class _SongsPageState extends State<SongsPage> {
  List<Map<String, dynamic>> songs = [];
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    widget.socketService.setOnMessage(_handleServerMessage);
    _requestSongsList();
  }

  void _handleServerMessage(String message) {
    try {
      final Map<String, dynamic> response = jsonDecode(message.trim());
      if (response['status'] != 'success' || response['data'] == null) {
        return;
      }
      final data = response['data'] as Map<String, dynamic>;
      if (data.containsKey('songs')) {
        final receivedSongs = data['songs'] as List;
        final newSongs = <Map<String, dynamic>>[];
        for (var song in receivedSongs) {
          if (song is Map) {
            final songMap = song as Map<String, dynamic>;
            newSongs.add({
              "title": songMap['name']?.toString() ?? 'Unknown',
              "artist": songMap['artist']?.toString() ?? widget.username,
              "base64Audio": songMap['base64Audio']?.toString() ?? '',
              "albumArtUrl": songMap['albumArtUrl']?.toString() ?? "https://via.placeholder.com/250",
            });
          }
        }
        setState(() {
          songs = newSongs;
        });
      } else if (data.containsKey('song')) {
        final song = data['song'] as Map<String, dynamic>;
        setState(() {
          songs.add({
            "title": song['name']?.toString() ?? 'Unknown',
            "artist": song['artist']?.toString() ?? widget.username,
            "base64Audio": song['base64Audio']?.toString() ?? '',
            "albumArtUrl": song['albumArtUrl']?.toString() ?? "https://via.placeholder.com/250",
          });
        });
      }
    } catch (e) {
      debugPrint('Error handling server message: $e');
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _requestSongsList() async {
    final message = {
      "requestType": "user",
      "action": "getSongs",
      "data": {
        "username": widget.username,
        "playlistname": "My Playlist"

      }
    };
    widget.socketService.sendMessage(message);
  }

  Future<void> _pickAndUploadSong() async {
    if (_isUploading) return;
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'm4a'],
      );
      if (result == null || result.files.single.path == null) return;
      setState(() {
        _isUploading = true;
      });
      File file = File(result.files.single.path!);
      List<int> fileBytes = await file.readAsBytes();
      String base64Audio = base64Encode(fileBytes);
      final message = {
        "requestType": "user",
        "action": "addSongToPlaylist",
        "data": {
            "username": widget.username,
            "playlistname": "My Playlist",
            "name": result.files.single.name,
            "artist": widget.username,
            "base64Audio": base64Audio,
            "musicPath": "",
            "releaseYear": 2023,
            "genre": "POP",
            "lyrics": "",
            "durationPlayed": 0,
            "album": ""

        }
      };
      widget.socketService.sendMessage(message);
    } catch (e) {
      debugPrint('Error uploading song: $e');
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: ListView.builder(
        itemCount: songs.length,
        itemBuilder: (context, index) {
          final song = songs[index];
          return ListTile(
            leading: Image.network(
              song["albumArtUrl"] as String,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(Icons.music_note, color: Colors.white70),
            ),
            title: Text(
              song["title"] as String,
              style: const TextStyle(color: Colors.white),
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              song["artist"] as String,
              style: const TextStyle(color: Colors.white70),
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () {
              if (song["base64Audio"] == null || (song["base64Audio"] as String).isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Audio data is missing')),
                );
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MusicPlayerPage(
                    title: song["title"] as String,
                    base64Audio: song["base64Audio"] as String,
                    artist: song["artist"] as String,
                    albumArtUrl: song["albumArtUrl"] as String,
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isUploading ? null : _pickAndUploadSong,
        backgroundColor: _isUploading ? Colors.grey : Colors.blueAccent,
        child: _isUploading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Icon(Icons.add, size: 30),
      ),
    );
  }
}