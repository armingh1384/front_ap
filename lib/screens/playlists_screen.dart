import 'package:flutter/material.dart';
import 'package:flutter_ap/services/playlist_service.dart';
import 'package:flutter_ap/mywidgets/playlist_item.dart';
import 'package:flutter_ap/models/playlist.dart';

class PlaylistsScreen extends StatefulWidget {
  final PlaylistService playlistService;

  const PlaylistsScreen({Key? key, required this.playlistService})
      : super(key: key);

  @override
  State<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends State<PlaylistsScreen> {
  List<Playlist> playlists = [];

  @override
  void initState() {
    super.initState();
    fetchPlaylists();
  }

  void fetchPlaylists() {
    widget.playlistService.getPlaylists((data) {
      setState(() {
        playlists = data;
      });
    });
  }

  void createPlaylist() async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Create Playlist", style: TextStyle(color: Colors.white, fontSize: 18)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Playlist name",
            hintStyle: TextStyle(color: Colors.grey[600]),
            filled: true,
            fillColor: Colors.grey[900],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              widget.playlistService.createPlaylist(controller.text);
              Navigator.pop(context);
              fetchPlaylists();
            },
            child: const Text("Create", style: TextStyle(color: Colors.deepPurpleAccent)),
          ),
        ],
      ),
    );
  }

  void deletePlaylist(String id) {
    widget.playlistService.deletePlaylist(id);
    fetchPlaylists();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Your Playlists', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: createPlaylist,
          ),
        ],
      ),
      body: playlists.isEmpty
          ? const Center(
        child: Text(
          'No playlists yet',
          style: TextStyle(color: Colors.grey),
        ),
      )
          : ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        itemCount: playlists.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final playlist = playlists[index];
          return PlaylistItem(
            playlist: playlist,
            onTap: () {},
            onDelete: () => deletePlaylist(playlist.id),
          );
        },
      ),
    );
  }
}
