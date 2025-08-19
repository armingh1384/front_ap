import 'package:flutter/material.dart';
import 'package:flutter_ap/screens/discover_page.dart';
import 'package:flutter_ap/screens/favorites_page.dart';
import 'package:flutter_ap/screens/profile_page.dart';
import 'package:flutter_ap/screens/sign_in_screen.dart';
import 'package:flutter_ap/screens/songpage.dart';
import 'package:flutter_ap/services/session_service.dart';
import 'package:flutter_ap/services/SocketService.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_ap/screens/MusicPlayer.dart';

class HomePage extends StatefulWidget {
  final String username;

  const HomePage({Key? key, required this.username}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  late final SocketService socketService;
  late final List<Widget> _pages;
  bool _showControlPanel = false;

  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  String _currentSongTitle = '';

  @override
  void initState() {
    super.initState();
    socketService = SocketService(host: '192.168.1.7', port: 10384);
    socketService.connect();

    _pages = [
      SongsPage(username: widget.username, socketService: socketService),
      const DiscoverPage(),
    FavoritesPage(username: widget.username, socketService: socketService),
      ProfilePage(username: widget.username),
    ];

    _audioPlayer = GlobalAudioPlayer().audioPlayer;

    _audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() {
        _isPlaying = state == PlayerState.playing;
      });
    });

    _audioPlayer.onDurationChanged.listen((duration) {
      setState(() {
        _totalDuration = duration;
      });
    });

    _audioPlayer.onPositionChanged.listen((position) {
      setState(() {
        _currentPosition = position;
      });
    });

    GlobalAudioPlayer().currentSongTitle.addListener(() {
      setState(() {
        _currentSongTitle = GlobalAudioPlayer().currentSongTitle.value;
      });
    });
  }

  @override
  void dispose() {
    socketService.disconnect();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _logout() async {
    await SessionService().clearSession();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => SignInScreen(
          onLoginSuccess: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => HomePage(username: widget.username),
              ),
            );
          },
        ),
      ),
    );
  }

  void _playNextSong() {
    GlobalAudioPlayer().playNext();
  }

  void _playPreviousSong() {
    GlobalAudioPlayer().playPrevious();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1D22),
        title: Row(
          children: const [
            Icon(Icons.music_note, color: Colors.white70),
            SizedBox(width: 8),
            Text(
              'Nava',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 22,
                color: Colors.white,
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          if (_currentSongTitle.isNotEmpty)
            IconButton(
              icon: Icon(Icons.settings, color: Colors.white70),
              onPressed: () {
                setState(() {
                  _showControlPanel = !_showControlPanel;
                });
              },
            ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            onPressed: _logout,
          ),
        ],
      ),
      body: Stack(
        children: [
          _pages[_selectedIndex],
          if (_showControlPanel) _buildControlPanel(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1A1D22),
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.purpleAccent,
        unselectedItemColor: Colors.grey[500],
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.library_music), label: 'Songs'),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Discover'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favorites'),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildControlPanel() {
    return Positioned(
      top: 80,
      right: 20,
      child: Container(
        width: 250,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Color(0xFF1A1D22).withOpacity(0.95),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.purpleAccent, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Control Panel',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.white70, size: 20),
                  onPressed: () {
                    setState(() {
                      _showControlPanel = false;
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.music_note, color: Colors.white70, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _currentSongTitle.isNotEmpty ? _currentSongTitle : 'No song playing',
                    style: TextStyle(color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            if (_currentSongTitle.isNotEmpty) ...[
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 3,
                  thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
                  activeTrackColor: Colors.purpleAccent,
                  inactiveTrackColor: Colors.grey[700],
                  thumbColor: Colors.white,
                ),
                child: Slider(
                  min: 0,
                  max: _totalDuration.inSeconds.toDouble(),
                  value: _currentPosition.inSeconds.toDouble().clamp(
                    0,
                    _totalDuration.inSeconds.toDouble(),
                  ),
                  onChanged: (value) {
                    _audioPlayer.seek(Duration(seconds: value.toInt()));
                  },
                ),
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_formatDuration(_currentPosition)}',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  Text(
                    '${_formatDuration(_totalDuration)}',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
              SizedBox(height: 12),
            ],
            Row(
              children: [
                Icon(Icons.speed, color: Colors.white70, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Slider(
                    min: 0.5,
                    max: 2.0,
                    divisions: 6,
                    value: GlobalAudioPlayer().playbackRate,
                    onChanged: (value) {
                      setState(() {
                        GlobalAudioPlayer().setPlaybackRate(value);
                      });
                    },
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  '${GlobalAudioPlayer().playbackRate.toStringAsFixed(1)}x',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
            SizedBox(height: 16),
            if (_currentSongTitle.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.skip_previous, color: Colors.white, size: 28),
                    onPressed: () {
                      GlobalAudioPlayer().playPrevious();
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                      color: Colors.white,
                      size: 36,
                    ),
                    onPressed: () async {
                      if (_isPlaying) {
                        await _audioPlayer.pause();
                      } else {
                        await _audioPlayer.resume();
                      }
                      setState(() {
                        _isPlaying = !_isPlaying;
                      });
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.skip_next, color: Colors.white, size: 28),
                    onPressed: () {
                      GlobalAudioPlayer().playNext();
                    },
                  ),
                ],
              )
,
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    return '${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
  }
}
