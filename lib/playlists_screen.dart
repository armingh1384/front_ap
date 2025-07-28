import 'package:flutter/material.dart';
import 'package:flutter_ap/services/playlist_service.dart';
import 'package:flutter_ap/widgets/playlist_item.dart';
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
        backgroundColor: Colors.grey[850],
        title: Text("New Playlist", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(hintText: "Playlist name"),
        ),
        actions: [
          TextButton(
            onPressed: () {
              widget.playlistService.createPlaylist(controller.text);
              Navigator.pop(context);
              fetchPlaylists();
            },
            child: Text("Create"),
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
      backgroundColor: Color(0xFF121212),
      appBar: AppBar(
        title: Text('Your Playlists'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: createPlaylist,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: playlists.length,
        itemBuilder: (context, index) {
          final playlist = playlists[index];
          return PlaylistItem(
            playlist: playlist,
            onTap: () {
               
            },
            onDelete: () => deletePlaylist(playlist.id),
          );
        },
      ),
    );
  }
}

