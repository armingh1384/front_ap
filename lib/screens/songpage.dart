import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ap/screens/MusicPlayer.dart';
import 'package:flutter_ap/services/SocketService.dart';

class SongsPage extends StatefulWidget {
  final String username;
  final SocketService socketService;

  const SongsPage({
    Key? key,
    required this.username,
    required this.socketService,
  }) : super(key: key);

  @override
  State<SongsPage> createState() => _SongsPageState();
}

class _SongsPageState extends State<SongsPage> {
  List<Map<String, dynamic>> songs = [];
  bool _isUploading = false;
  bool _isLoadingGlobal = false;

  @override
  void initState() {
    super.initState();
    widget.socketService.setOnMessage(_handleServerMessage);
    _requestSongsList();
  }

  void _handleServerMessage(String message) {
    try {
      final Map<String, dynamic> response = jsonDecode(message.trim());
      if (response['status'] != 'success' || response['data'] == null) return;

      final data = response['data'] as Map<String, dynamic>;

      if (data.containsKey('globalsongs')) {
        _showGlobalSongsDialog(data['globalsongs'] as List);
        return;
      }

      final newSongs = <Map<String, dynamic>>[];

      if (data.containsKey('songs')) {
        for (var song in data['songs'] as List) {
          if (song is Map) {
            final songMap = song as Map<String, dynamic>;
            newSongs.add({
              "id": songMap['id']?.toString() ?? UniqueKey().toString(),
              "title": songMap['name']?.toString() ?? 'Unknown',
              "artist": songMap['artist']?.toString() ?? widget.username,
              "base64Audio": songMap['base64Audio']?.toString() ?? '',
              "genre": songMap['genre']?.toString() ?? 'POP',
            });
          }
        }
      } else if (data.containsKey('song')) {
        final song = data['song'] as Map<String, dynamic>;
        newSongs.add({
          "id": song['id']?.toString() ?? UniqueKey().toString(),
          "title": song['name']?.toString() ?? 'Unknown',
          "artist": song['artist']?.toString() ?? widget.username,
          "base64Audio": song['base64Audio']?.toString() ?? '',
          "genre": song['genre']?.toString() ?? 'POP',
        });
      }

      setState(() {
        songs = newSongs;
        _isUploading = false;
        _isLoadingGlobal = false;
      });
    } catch (e) {
      setState(() {
        _isUploading = false;
        _isLoadingGlobal = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
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

      setState(() => _isUploading = true);

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
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: ${e.toString()}')),
      );
    }
  }

  Future<void> _addToGlobal(Map<String, dynamic> song) async {
    setState(() => _isUploading = true);

    try {
      final message = {
        "requestType": "user",
        "action": "AddtoNava",
        "data": {
          "username": widget.username,
          "name": song["title"],
          "base64": song["base64Audio"],
          "genre": song["genre"] ?? "POP",
        }
      };

      widget.socketService.sendMessage(message);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adding to global library...')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _importFromGlobal() async {
    setState(() => _isLoadingGlobal = true);

    final message = {
      "requestType": "user",
      "action": "ImportFromNava",
      "data": {}
    };

    widget.socketService.sendMessage(message);
  }

  Future<void> _showGlobalSongsDialog(List globalSongs) async {
    setState(() => _isLoadingGlobal = false);

    final selected = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Global Music Library'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: globalSongs.length,
            itemBuilder: (context, index) {
              final song = globalSongs[index];
              return ListTile(
                leading: const Icon(Icons.music_note, color: Colors.purple),
                title: Text(song['name'] ?? 'Unknown'),
                subtitle: Text('By: ${song['username'] ?? 'Unknown'}'),
                onTap: () => Navigator.pop(context, song),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selected != null) {
      setState(() => _isUploading = true);

      try {
        final importMessage = {
          "requestType": "user",
          "action": "addSongToPlaylist",
          "data": {
            "username": widget.username,
            "playlistname": "My Playlist",
            "name": selected["name"],
            "artist": selected["username"] ?? "Global",
            "base64Audio": selected["base64"],
            "musicPath": "",
            "releaseYear": 2023,
            "genre": selected["genre"] ?? "POP",
            "lyrics": "",
            "durationPlayed": 0,
            "album": ""
          }
        };

        widget.socketService.sendMessage(importMessage);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Song imported successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: ${e.toString()}')),
        );
      } finally {
        setState(() => _isUploading = false);
      }
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('My Playlist'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _requestSongsList,
          ),
        ],
      ),
      body: _isUploading || _isLoadingGlobal
          ? const Center(child: CircularProgressIndicator())
          : songs.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.music_off, size: 50, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No songs found'),
            TextButton(
              onPressed: _importFromGlobal,
              child: const Text('Import from Global Library'),
            ),
          ],
        ),
      )
          : ListView.builder(
        itemCount: songs.length,
        itemBuilder: (context, index) {
          final song = songs[index];
          return Card(
            margin: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 4),
            color: Colors.grey[900],
            child: ListTile(
              leading: _buildImageWidget(),
              title: Text(
                song["title"] as String,
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                song["artist"] as String,
                style: const TextStyle(color: Colors.white70),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MusicPlayerPage(
                      playlist: songs,
                      initialIndex: index,
                    ),
                  ),
                );
              },
              trailing: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white70),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'add_to_global',
                    child: Text('Add to Global Library'),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'add_to_global') {
                    _addToGlobal(song);
                  }
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _isUploading ? null : _pickAndUploadSong,
            backgroundColor: Colors.purpleAccent,
            child: _isUploading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Icon(Icons.add),
            heroTag: 'upload',
            tooltip: 'Upload Song',
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: _isLoadingGlobal ? null : _importFromGlobal,
            backgroundColor: Colors.blueAccent,
            child: _isLoadingGlobal
                ? const CircularProgressIndicator(color: Colors.white)
                : const Icon(Icons.cloud_download),
            heroTag: 'import',
            tooltip: 'Import from Global',
          ),
        ],
      ),
    );
  }
}