class Song {
  final String id;
  final String title;
  final String artist;
  final int releaseYear;
  final bool liked;
  final String? genre; // ژانر آهنگ (اختیاری)

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.releaseYear,
    this.liked = false,
    this.genre,
  });

  /// ساخت آبجکت از داده دریافتی از سرور (JSON)
  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      artist: json['artist'] ?? '',
      releaseYear: json['releaseYear'] is int
          ? json['releaseYear']
          : int.tryParse(json['releaseYear'].toString()) ?? 0,
      liked: json['liked'] ?? false,
      genre: json['genre'], // ممکن است null باشد
    );
  }

  /// تبدیل به JSON برای ارسال به سرور
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'releaseYear': releaseYear,
      'liked': liked,
      'genre': genre,
    };
  }

  /// ایجاد نسخه جدید از آهنگ با تغییر دلخواه یک یا چند ویژگی
  Song copyWith({
    String? id,
    String? title,
    String? artist,
    int? releaseYear,
    bool? liked,
    String? genre,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      releaseYear: releaseYear ?? this.releaseYear,
      liked: liked ?? this.liked,
      genre: genre ?? this.genre,
    );
  }

  @override
  String toString() {
    return 'Song(title: $title, artist: $artist, year: $releaseYear, liked: $liked, genre: $genre)';
  }
}
