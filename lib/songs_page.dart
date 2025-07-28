import 'package:flutter/material.dart';
import 'package:flutter_ap/models/song.dart';
import 'package:flutter_ap/widgets/data_collector.dart';

class SongsPage extends StatefulWidget {
  const SongsPage({Key? key}) : super(key: key);

  @override
  _SongsPageState createState() => _SongsPageState();
}

class _SongsPageState extends State<SongsPage> {
  List<Song> allSongs = [
    Song(title: 'Bohemian Rhapsody', artist: 'Queen', releaseYear: 1975, genre: 'Rock'),
    Song(title: 'Billie Jean', artist: 'Michael Jackson', releaseYear: 1982, genre: 'Pop'),
    Song(title: 'Imagine', artist: 'John Lennon', releaseYear: 1971, genre: 'Pop'),
    Song(title: 'Blinding Lights', artist: 'The Weeknd', releaseYear: 2019, genre: 'Synthpop'),
    Song(title: 'Shape of You', artist: 'Ed Sheeran', releaseYear: 2017, genre: 'Pop'),
  ];

  String searchQuery = '';
  int? selectedYear;

  List<int> get availableYears {
    return allSongs.map((s) => s.releaseYear).toSet().toList()..sort();
  }

  List<Song> get filteredSongs {
    return allSongs.where((song) {
      final matchesQuery = song.title.toLowerCase().contains(searchQuery.toLowerCase());
      final matchesYear = selectedYear == null || song.releaseYear == selectedYear;
      return matchesQuery && matchesYear;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '🎧 لیست آهنگ‌ها',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _buildSearchField(),
            const SizedBox(height: 10),
            _buildYearDropdown(),
            const SizedBox(height: 20),
            Expanded(child: _buildSongList()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      onChanged: (value) => setState(() => searchQuery = value),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'جستجو بر اساس نام آهنگ...',
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.grey[850],
        prefixIcon: const Icon(Icons.search, color: Colors.white),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _buildYearDropdown() {
    return DropdownButtonFormField<int>(
      value: selectedYear,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey[850],
        hintText: 'فیلتر بر اساس سال انتشار',
        hintStyle: const TextStyle(color: Colors.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
      ),
      dropdownColor: Colors.grey[900],
      iconEnabledColor: Colors.white,
      style: const TextStyle(color: Colors.white),
      items: [
        const DropdownMenuItem(value: null, child: Text('همه سال‌ها')),
        ...availableYears.map((year) => DropdownMenuItem(
              value: year,
              child: Text(year.toString()),
            )),
      ],
      onChanged: (value) => setState(() => selectedYear = value),
    );
  }

  Widget _buildSongList() {
    if (filteredSongs.isEmpty) {
      return const Center(
        child: Text(
          '🎵 هیچ آهنگی مطابق فیلتر پیدا نشد',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredSongs.length,
      itemBuilder: (context, index) {
        final song = filteredSongs[index];
        return Card(
          color: const Color(0xFF1C1C1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.only(bottom: 16.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DataCollector(label: '🎶 نام', value: song.title),
                DataCollector(label: '👤 خواننده', value: song.artist),
                DataCollector(label: '📅 سال انتشار', value: song.releaseYear.toString()),
                DataCollector(label: '🎼 ژانر', value: song.genre ?? '—'),
              ],
            ),
          ),
        );
      },
    );
  }
}
