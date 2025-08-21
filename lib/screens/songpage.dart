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
  Map<String, List<Map<String, dynamic>>> playlists = {};
  bool _isUploading = false;
  bool _isLoadingGlobal = false;
  String? currentPlaylist;
  Map<String, List<int>> selectedIndicesPerPlaylist = {};
  List<String> allPlaylistNames = [];

  @override
  void initState() {
    super.initState();
    widget.socketService.setOnMessage(_handleServerMessage);
    _requestAllPlaylists();
  }

  Future<void> _requestAllPlaylists() async {
    final message = {
      "requestType": "user",
      "action": "getPlaylists",
      "data": {
        "username": widget.username
      }
    };
    widget.socketService.sendMessage(message);
  }

  void _handleServerMessage(String message) {
    try {
      final Map<String, dynamic> response = jsonDecode(message.trim());
      if (response['status'] != 'success' || response['data'] == null) return;
      final data = response['data'] as Map<String, dynamic>;

      if (data.containsKey('playlists')) {
        final List<dynamic> receivedPlaylists = data['playlists'] as List;
        Map<String, List<Map<String, dynamic>>> newPlaylists = {};
        List<String> playlistNames = [];

        for (var playlistData in receivedPlaylists) {
          final String playlistName = playlistData['playlistname']?.toString() ?? "Unknown Playlist";
          playlistNames.add(playlistName);
          final List<Map<String, dynamic>> songs = [];

          if (playlistData.containsKey('songs')) {
            for (var song in playlistData['songs'] as List) {
              if (song is Map) {
                final songMap = song as Map<String, dynamic>;
                songs.add({
                  "id": songMap['id']?.toString() ?? UniqueKey().toString(),
                  "title": songMap['name']?.toString() ?? 'Unknown',
                  "artist": songMap['artist']?.toString() ?? widget.username,
                  "base64Audio": songMap['base64Audio']?.toString() ?? '',
                  "genre": songMap['genre']?.toString() ?? 'POP',
                  "countOfLikes": songMap['countOfLikes'] ?? 0,
                  "isLiked": songMap['isLiked'] ?? false,
                  "album": songMap['album']?.toString() ?? '',
                  "releaseYear": songMap['releaseYear'] ?? 2023,
                });
              }
            }
          }
          newPlaylists[playlistName] = songs;
        }

        setState(() {
          playlists = newPlaylists;
          allPlaylistNames = playlistNames;
          for (var name in playlistNames) {
            selectedIndicesPerPlaylist[name] = [];
          }
          _isUploading = false;
          _isLoadingGlobal = false;
        });
        return;
      }

      if (data.containsKey('globalsongs')) {
        _showGlobalSongsDialog(data['globalsongs'] as List);
        return;
      }

      if (response['action'] == 'likeSongResponse') {
        _requestAllPlaylists();
        return;
      }

      if (response['action'] == 'removePlaylistResponse') {
        _requestAllPlaylists();
        return;
      }

      if (response['action'] == 'removeSongResponse') {
        _requestAllPlaylists();
        return;
      }

      if (response['action'] == 'AddToNavaResponse') {
        _requestAllPlaylists();
        return;
      }

      _requestAllPlaylists();
    } catch (e) {
      setState(() {
        _isUploading = false;
        _isLoadingGlobal = false;
      });
    }
  }

  Future<void> _pickAndUploadSong() async {
    if (_isUploading) return;
    String? playlistName = await _askPlaylistNameDialog();
    if (playlistName == null || playlistName.isEmpty) return;

    setState(() {
      currentPlaylist = playlistName;
      _isUploading = true;
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'm4a'],
      );

      if (result == null || result.files.single.path == null) {
        setState(() => _isUploading = false);
        return;
      }

      File file = File(result.files.single.path!);
      List<int> fileBytes = await file.readAsBytes();
      String base64Audio = base64Encode(fileBytes);

      final message = {
        "requestType": "user",
        "action": "addSongToPlaylist",
        "data": {
          "username": widget.username,
          "playlistname": playlistName,
          "name": result.files.single.name,
          "artist": widget.username,
          "base64Audio": base64Audio,
          "musicPath": "",
          "releaseYear": 2023,
          "genre": "POP",
          "lyrics": "",
          "durationPlayed": 0,
          "album": "",
          "countOfLikes": 0,
          "isLiked": false
        }
      };

      widget.socketService.sendMessage(message);
    } catch (e) {
      setState(() => _isUploading = false);
    }
  }

  Future<String?> _askPlaylistNameDialog() async {
    String? playlistName;
    await showDialog(
      context: context,
      builder: (context) {
        TextEditingController controller = TextEditingController();
        return AlertDialog(
          title: const Text('Enter Playlist Name'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Playlist name'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () {
                playlistName = controller.text.trim();
                Navigator.pop(context);
              },
              child: const Text('Submit'),
            ),
            TextButton(
              onPressed: () {
                playlistName = null;
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
    return playlistName;
  }

  Future<void> _addSelectedToNava(String playlistName) async {
    final selectedIndices = selectedIndicesPerPlaylist[playlistName] ?? [];
    if (selectedIndices.isEmpty) return;

    setState(() => _isUploading = true);

    try {
      final songs = playlists[playlistName] ?? [];
      for (int index in selectedIndices) {
        final song = songs[index];
        final message = {
          "requestType": "user",
          "action": "AddToNava",
          "data": {
            "username": widget.username,
            "name": song["title"],
            "base64Audio": song["base64Audio"],
            "genre": song["genre"] ?? "POP",
            "artist": song["artist"] ?? widget.username,
            "album": song["album"] ?? "",
            "releaseYear": song["releaseYear"] ?? 2023,
            "countOfLikes":song["countOfLikes"]
          }
        };
        widget.socketService.sendMessage(message);
        await Future.delayed(const Duration(milliseconds: 200));
      }

      setState(() {
        selectedIndicesPerPlaylist[playlistName] = [];
      });
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _removeSelectedSongs(String playlistName) async {
    final selectedIndices = selectedIndicesPerPlaylist[playlistName] ?? [];
    if (selectedIndices.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete ${selectedIndices.length} song(s)?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isUploading = true);
      try {
        final songs = playlists[playlistName] ?? [];
        for (int index in selectedIndices) {
          final song = songs[index];
          final message = {
            "requestType": "user",
            "action": "removeSongFromPlaylist",
            "data": {
              "playlistname": playlistName,
              "username": widget.username,
              "name": song["title"],
              "base64Audio": song["base64Audio"],
              "genre": song["genre"] ?? "POP",
              "artist": song["artist"] ?? widget.username,
              "album": song["album"] ?? "",
              "releaseYear": song["releaseYear"] ?? 2023,
            }
          };
          widget.socketService.sendMessage(message);
          await Future.delayed(const Duration(milliseconds: 200));
        }

        setState(() {
          selectedIndicesPerPlaylist[playlistName] = [];
        });
      } finally {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _importFromGlobal() async {
    String? playlistName = await _askPlaylistNameDialog();
    if (playlistName == null || playlistName.isEmpty) return;

    setState(() {
      currentPlaylist = playlistName;
      _isLoadingGlobal = true;
    });

    final message = {
      "requestType": "user",
      "action": "ImportFromNava",
      "data": {}
    };
    widget.socketService.sendMessage(message);
  }

  Future<void> _showGlobalSongsDialog(List globalSongs) async {
    setState(() => _isLoadingGlobal = false);
    List<int> selectedIndices = [];
    String playlistName = currentPlaylist ?? "My Playlist";

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Global Music Library'),
        content: SizedBox(
          width: double.maxFinite,
          child: StatefulBuilder(
            builder: (context, setStateDialog) {
              return ListView.builder(
                shrinkWrap: true,
                itemCount: globalSongs.length,
                itemBuilder: (context, index) {
                  final song = globalSongs[index];
                  final isSelected = selectedIndices.contains(index);
                  return ListTile(
                    leading: const Icon(Icons.music_note, color: Colors.purple),
                    title: Text(song['name'] ?? 'Unknown'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('By: ${song['username'] ?? 'Unknown'}'),
                        Text('Genre: ${song['genre'] ?? 'Unknown'}'),
                        if (song['countOfLikes'] != null)
                          Text('Likes: ${song['countOfLikes']}'),
                      ],
                    ),
                    tileColor: isSelected ? Colors.purple.shade100 : null,
                    onTap: () {
                      setStateDialog(() {
                        if (isSelected) {
                          selectedIndices.remove(index);
                        } else {
                          selectedIndices.add(index);
                        }
                      });
                    },
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null,
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, selectedIndices),
            child: const Text('Import Selected'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    ).then((selectedIndices) async {
      if (selectedIndices != null && selectedIndices is List<int> && selectedIndices.isNotEmpty) {
        setState(() => _isUploading = true);
        try {
          for (var index in selectedIndices) {
            final selected = globalSongs[index];
            final importMessage = {
              "requestType": "user",
              "action": "addSongToPlaylist",
              "data": {
                "username": widget.username,
                "playlistname": playlistName,
                "name": selected["name"],
                "artist": selected["username"] ?? "Global",
                "base64Audio": selected["base64"],
                "musicPath": "",
                "releaseYear": selected["releaseYear"] ?? 2023,
                "genre": selected["genre"] ?? "POP",
                "lyrics": "",
                "durationPlayed": 0,
                "album": selected["album"] ?? "",
                "countOfLikes": selected["countOfLikes"] ?? 0,
                "isLiked": false
              }
            };
            widget.socketService.sendMessage(importMessage);
            await Future.delayed(const Duration(milliseconds: 200));
          }
          _requestAllPlaylists();
        } finally {
          setState(() => _isUploading = false);
        }
      }
    });
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

  void _toggleSelection(String playlistName, int index) {
    setState(() {
      List<int> selected = selectedIndicesPerPlaylist[playlistName] ?? [];
      if (selected.contains(index)) {
        selected.remove(index);
      } else {
        selected.add(index);
      }
      selectedIndicesPerPlaylist[playlistName] = selected;
    });
  }

  Future<void> _showAddPlaylistDialog() async {
    String? playlistName = await _askPlaylistNameDialog();
    if (playlistName != null && playlistName.isNotEmpty) {
      setState(() {
        playlists[playlistName] = [];
        selectedIndicesPerPlaylist[playlistName] = [];
        allPlaylistNames.add(playlistName);
      });

      final message = {
        "requestType": "user",
        "action": "createPlaylist",
        "data": {
          "username": widget.username,
          "playlistname": playlistName,
        }
      };

      widget.socketService.sendMessage(message);
    }
  }

  Future<void> _removePlaylist(String playlistName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete the playlist "$playlistName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isUploading = true);
      final message = {
        "requestType": "user",
        "action": "removePlaylist",
        "data": {
          "username": widget.username,
          "playlistname": playlistName,
        }
      };
      widget.socketService.sendMessage(message);
    }
  }

  Future<void> _toggleLikeSong(String playlistName, Map<String, dynamic> song, bool isCurrentlyLiked) async {
    setState(() {
      final songs = playlists[playlistName];
      if (songs != null) {
        final songIndex = songs.indexWhere((s) => s['id'] == song['id']);
        if (songIndex != -1) {
          final currentLikes = songs[songIndex]['countOfLikes'] ?? 0;
          songs[songIndex] = {
            ...songs[songIndex],
            'isLiked': !isCurrentlyLiked,
            'countOfLikes': isCurrentlyLiked ? currentLikes - 1 : currentLikes + 1,
          };
        }
      }
    });

    final message = {
      "requestType": "user",
      "action": "likeSong",
      "data": {
        "username": widget.username,
        "playlistname": playlistName,
        "name": song["title"],
        "isLiked": !isCurrentlyLiked,
      }
    };

    widget.socketService.sendMessage(message);
  }

  @override
  Widget build(BuildContext context) {
    final playlistNames = playlists.keys.toList();
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Playlists'),
        backgroundColor: Colors.purple[900],
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddPlaylistDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: _isLoadingGlobal
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : const Icon(Icons.cloud_download),
                    label: const Text('Import from Global'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: _isLoadingGlobal ? null : _importFromGlobal,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: _isUploading
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : const Icon(Icons.add),
                    label: const Text('Upload Song'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: _isUploading ? null : _pickAndUploadSong,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isUploading || _isLoadingGlobal
                ? const Center(child: CircularProgressIndicator(color: Colors.purple))
                : playlists.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.music_off, size: 50, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No playlists found',
                    style: TextStyle(color: Colors.white70, fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Create New Playlist'),
                    onPressed: _showAddPlaylistDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                    ),
                  ),
                ],
              ),
            )
                : ListView(
              children: playlistNames.map((playlistName) {
                final songs = playlists[playlistName]!;
                final selectedIndices = selectedIndicesPerPlaylist[playlistName] ?? [];
                final hasSelection = selectedIndices.isNotEmpty;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  color: Colors.grey[900],
                  child: ExpansionTile(
                    title: Row(
                      children: [
                        const Icon(Icons.queue_music, color: Colors.purpleAccent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            playlistName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (!hasSelection)
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () => _removePlaylist(playlistName),
                          ),
                      ],
                    ),
                    children: [
                      if (songs.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Center(
                            child: Column(
                              children: [
                                const Icon(Icons.music_off, color: Colors.grey, size: 40),
                                const SizedBox(height: 8),
                                const Text(
                                  'This playlist is empty',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          itemCount: songs.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            final song = songs[index];
                            final isSelected = selectedIndices.contains(index);
                            final isLiked = song['isLiked'] ?? false;

                            return InkWell(
                              onLongPress: () => _toggleSelection(playlistName, index),
                              onTap: () {
                                if (hasSelection) {
                                  _toggleSelection(playlistName, index);
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => MusicPlayerPage(
                                        playlist: songs,
                                        initialIndex: index,
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.purple.withOpacity(0.3)
                                      : Colors.grey[850],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ListTile(
                                  leading: _buildImageWidget(),
                                  title: Text(
                                    song["title"] as String,
                                    style: const TextStyle(color: Colors.white),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    '${song["artist"] as String} • ${song["album"] ?? "No Album"}',
                                    style: const TextStyle(color: Colors.white70),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (hasSelection)
                                        Icon(
                                          Icons.check_circle,
                                          color: isSelected ? Colors.green : Colors.transparent,
                                        )
                                      else
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: Icon(
                                                isLiked ? Icons.favorite : Icons.favorite_border,
                                                color: isLiked ? Colors.red : Colors.white70,
                                              ),
                                              onPressed: () => _toggleLikeSong(
                                                playlistName,
                                                song,

                                                isLiked,
                                              ),
                                              iconSize: 20,
                                              padding: EdgeInsets.zero,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              song['countOfLikes']?.toString() ?? '0',
                                              style: TextStyle(
                                                color: isLiked ? Colors.red : Colors.white70,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      if (hasSelection)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: _isUploading
                                      ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                      : const Icon(Icons.share),
                                  label: Text('Add ${selectedIndices.length} to Nava'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  onPressed: _isUploading
                                      ? null
                                      : () => _addSelectedToNava(playlistName),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: _isUploading
                                      ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                      : const Icon(Icons.delete, color: Colors.white),
                                  label: Text('Delete ${selectedIndices.length}'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  onPressed: _isUploading
                                      ? null
                                      : () => _removeSelectedSongs(playlistName),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}