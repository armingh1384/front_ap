class Playlist {
  final String id;
  final String name;
  final List<String> songIds;

  Playlist({
    required this.id,
    required this.name,
    required this.songIds,
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'],
      name: json['name'],
      songIds: List<String>.from(json['songIds']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'songIds': songIds,
    };
  }
}
