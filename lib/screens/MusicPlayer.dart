import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';

class GlobalAudioPlayer {
  static final GlobalAudioPlayer _instance = GlobalAudioPlayer._internal();
  factory GlobalAudioPlayer() => _instance;

  final AudioPlayer audioPlayer = AudioPlayer();
  String? _tempFilePath;

  final ValueNotifier<bool> isPlaying = ValueNotifier(false);
  final ValueNotifier<String> currentSongTitle = ValueNotifier('');
  final ValueNotifier<Duration> currentPosition = ValueNotifier(Duration.zero);
  final ValueNotifier<Duration> totalDuration = ValueNotifier(Duration.zero);

  final ValueNotifier<List<Map<String, dynamic>>> currentPlaylist = ValueNotifier([]);
  final ValueNotifier<int> currentIndex = ValueNotifier(0);

  double playbackRate = 1.0;

  Future<void> Function()? onNextPressed;
  Future<void> Function()? onPreviousPressed;
  VoidCallback? onPlayPausePressed;

  StreamSubscription? _posSub;
  StreamSubscription? _durSub;
  StreamSubscription? _stateSub;
  StreamSubscription? _completeSub;

  GlobalAudioPlayer._internal() {
    _posSub = audioPlayer.onPositionChanged.listen((pos) {
      currentPosition.value = pos;
    });
    _durSub = audioPlayer.onDurationChanged.listen((dur) {
      totalDuration.value = dur;
    });
    _stateSub = audioPlayer.onPlayerStateChanged.listen((state) {
      isPlaying.value = state == PlayerState.playing;
    });
    _completeSub = audioPlayer.onPlayerComplete.listen((_) async {
      await playNext();
    });
  }

  Future<void> _disposeTempFile() async {
    if (_tempFilePath != null) {
      try {
        final f = File(_tempFilePath!);
        if (await f.exists()) await f.delete();
      } catch (_) {}
      _tempFilePath = null;
    }
  }

  Future<void> setPlaybackRate(double rate) async {
    playbackRate = rate;
    await audioPlayer.setPlaybackRate(rate);
  }

  Future<void> _playFromCurrentIndex() async {
    if (currentPlaylist.value.isEmpty) return;
    final i = currentIndex.value;
    final song = currentPlaylist.value[i];

    final bytes = base64Decode(song['base64Audio']);
    final tempDir = await getTemporaryDirectory();
    await _disposeTempFile();
    final file = File('${tempDir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.mp3');
    await file.writeAsBytes(bytes);
    _tempFilePath = file.path;

    await audioPlayer.setSource(DeviceFileSource(file.path));
    await audioPlayer.setPlaybackRate(playbackRate);
    await audioPlayer.resume();

    currentSongTitle.value = (song['title'] ?? '').toString();
    isPlaying.value = true;
  }
  Future<void> reset() async {
    try {
      if (audioPlayer != null) {
        try {
          await audioPlayer.stop();
        } catch (e) {
          print('Error stopping audio: $e');
        }
      }
    } catch (e) {
      print('Reset error: $e');
    }

    try {
      await _disposeTempFile();
    } catch (e) {
      print('Error disposing file: $e');
    }

    currentSongTitle.value = '';
    isPlaying.value = false;
    currentPosition.value = Duration.zero;
    totalDuration.value = Duration.zero;
    currentPlaylist.value = [];
    currentIndex.value = 0;
    playbackRate = 1.0;
  }
  Future<void> playNext() async {
    if (onNextPressed != null) {
      await onNextPressed!.call();
      return;
    }
    if (currentPlaylist.value.isEmpty) return;
    await audioPlayer.stop();
    currentIndex.value = (currentIndex.value + 1) % currentPlaylist.value.length;
    await _playFromCurrentIndex();
  }

  Future<void> playPrevious() async {
    if (onPreviousPressed != null) {
      await onPreviousPressed!.call();
      return;
    }
    if (currentPlaylist.value.isEmpty) return;
    await audioPlayer.stop();
    currentIndex.value =
        (currentIndex.value - 1 + currentPlaylist.value.length) %
            currentPlaylist.value.length;
    await _playFromCurrentIndex();
  }

  Future<void> togglePlayPause() async {
    if (isPlaying.value) {
      await audioPlayer.pause();
      isPlaying.value = false;
    } else {
      await audioPlayer.resume();
      isPlaying.value = true;
    }
    onPlayPausePressed?.call();
  }

  Future<void> seekSeconds(int seconds) async {
    await audioPlayer.seek(Duration(seconds: seconds));
  }

  Future<void> dispose() async {
    await _disposeTempFile();
    await _posSub?.cancel();
    await _durSub?.cancel();
    await _stateSub?.cancel();
    await _completeSub?.cancel();
    await audioPlayer.dispose();
  }
}

class MusicPlayerPage extends StatefulWidget {
  final List<Map<String, dynamic>> playlist;
  final int initialIndex;

  const MusicPlayerPage({
    Key? key,
    required this.playlist,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  State<MusicPlayerPage> createState() => _MusicPlayerPageState();
}

class _MusicPlayerPageState extends State<MusicPlayerPage>
    with TickerProviderStateMixin {
  final GlobalAudioPlayer _globalPlayer = GlobalAudioPlayer();
  final AudioPlayer _audioPlayer = GlobalAudioPlayer().audioPlayer;

  int _currentIndex = 0;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  double _volume = 1.0;
  bool _audioReady = false;
  double _playbackRate = 1.0;

  late AnimationController _albumArtController;
  late AnimationController _controlsController;
  late AnimationController _bgController;
  late Animation<double> _albumArtAnimation;
  late Animation<double> _controlsAnimation;
  late Animation<double> _bgAnimation;

  StreamSubscription? _positionSub;
  StreamSubscription? _durationSub;
  StreamSubscription? _stateSub;
  StreamSubscription? _completeSub;
  bool _disposed = false;
  bool _showControlPanel = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;

    _albumArtController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _albumArtAnimation = Tween(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _albumArtController, curve: Curves.easeInOutSine),
    );
    _controlsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _controlsAnimation = CurvedAnimation(
      parent: _controlsController,
      curve: Curves.easeOutQuint,
    );
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
    _bgAnimation = Tween(begin: 0.0, end: 1.0).animate(_bgController);

    // اتصال callbackها به این صفحه (وقتی صفحه هست)
    _globalPlayer.onNextPressed = _nextSong;
    _globalPlayer.onPreviousPressed = _prevSong;
    _globalPlayer.onPlayPausePressed = _togglePlayPause;

    // پلی‌لیست و ایندکس سراسری
    _globalPlayer.currentPlaylist.value = widget.playlist;
    _globalPlayer.currentIndex.value = _currentIndex;

    _listenAudioEvents();
    _prepareAudio();
    _controlsController.forward();

    _globalPlayer.isPlaying.value = _isPlaying;
    _globalPlayer.currentSongTitle.value = widget.playlist[_currentIndex]['title'];
    _globalPlayer.totalDuration.value = _duration;
  }

  Future<void> _prepareAudio() async {
    try {
      final song = widget.playlist[_currentIndex];
      final bytes = base64Decode(song['base64Audio']);
      final tempDir = await getTemporaryDirectory();
      await _globalPlayer._disposeTempFile();
      final file = File('${tempDir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.mp3');
      await file.writeAsBytes(bytes);
      _globalPlayer._tempFilePath = file.path;

      await _audioPlayer.setSource(DeviceFileSource(file.path));
      await _audioPlayer.setVolume(_volume);
      await _audioPlayer.setPlaybackRate(_playbackRate);
      await _audioPlayer.resume();

      if (!_disposed && mounted) {
        setState(() {
          _isPlaying = true;
          _audioReady = true;
        });
        _globalPlayer.isPlaying.value = true;
        _globalPlayer.currentSongTitle.value = song['title'];
        _globalPlayer.currentIndex.value = _currentIndex;
      }
    } catch (_) {
      if (!_disposed && mounted) {
        setState(() => _audioReady = false);
      }
    }
  }

  void _listenAudioEvents() {
    _positionSub = _audioPlayer.onPositionChanged.listen((pos) {
      if (!_disposed && mounted) {
        setState(() => _position = pos);
        _globalPlayer.currentPosition.value = pos;
      }
    });
    _durationSub = _audioPlayer.onDurationChanged.listen((dur) {
      if (!_disposed && mounted) {
        setState(() => _duration = dur);
        _globalPlayer.totalDuration.value = dur;
      }
    });
    _stateSub = _audioPlayer.onPlayerStateChanged.listen((state) {
      if (!_disposed && mounted) {
        setState(() => _isPlaying = state == PlayerState.playing);
        _globalPlayer.isPlaying.value = state == PlayerState.playing;
      }
    });
    _completeSub = _audioPlayer.onPlayerComplete.listen((_) {
      if (!_disposed && mounted) {
        _nextSong();
      }
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _albumArtController.dispose();
    _controlsController.dispose();
    _bgController.dispose();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _stateSub?.cancel();
    _completeSub?.cancel();

    _globalPlayer.onNextPressed = null;
    _globalPlayer.onPreviousPressed = null;
    _globalPlayer.onPlayPausePressed = null;

    super.dispose();
  }

  void _togglePlayPause() {
    if (!_audioReady) return;
    if (_isPlaying) {
      _audioPlayer.pause();
      _globalPlayer.isPlaying.value = false;
    } else {
      _audioPlayer.resume();
      _globalPlayer.isPlaying.value = true;
    }
  }

  void _seekToSeconds(int seconds) {
    if (!_audioReady) return;
    _audioPlayer.seek(Duration(seconds: seconds));
  }

  Future<void> _nextSong() async {
    if (!_audioReady) return;
    await _audioPlayer.stop();
    if (!_disposed && mounted) {
      setState(() => _currentIndex = (_currentIndex + 1) % widget.playlist.length);
      _globalPlayer.currentIndex.value = _currentIndex;
    }
    await _prepareAudio();
    _albumArtController.reset();
    _albumArtController.forward();
  }

  Future<void> _prevSong() async {
    if (!_audioReady) return;
    await _audioPlayer.stop();
    if (!_disposed && mounted) {
      setState(() => _currentIndex = (_currentIndex - 1 + widget.playlist.length) % widget.playlist.length);
      _globalPlayer.currentIndex.value = _currentIndex;
    }
    await _prepareAudio();
    _albumArtController.reset();
    _albumArtController.forward();
  }

  Future<void> _changePlaybackRate(double rate) async {
    if (!_audioReady) return;
    setState(() => _playbackRate = rate);
    await _globalPlayer.setPlaybackRate(rate);
  }

  String _formatDuration(Duration d) {
    return '${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final song = widget.playlist[_currentIndex];
    final size = MediaQuery.of(context).size;

    return WillPopScope(
      onWillPop: () async => true,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: _AnimatedTitle(text: song['title']),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.settings, color: Colors.white),
              onPressed: () {
                setState(() => _showControlPanel = !_showControlPanel);
              },
            ),
          ],
        ),
        body: Stack(
          children: [
            _buildParallaxBackground(song['albumArtUrl'], size),
            Column(
              children: [
                Expanded(
                  child: Center(child: _buildAlbumArt(song['albumArtUrl'])),
                ),
                _buildSongInfo(song),
                _buildSlider(),
                _buildPlaybackRateControl(),
                _buildControls(),
                _buildVolume(),
                SizedBox(height: size.height * 0.05),
              ],
            ),
            if (_showControlPanel) _buildControlPanel(),
          ],
        ),
      ),
    );
  }

  Widget _buildControlPanel() {
    return Positioned(
      top: 100,
      right: 20,
      child: Container(
        width: 250,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.purpleAccent, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'کنترل وضعیت پخش',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.music_note, color: Colors.white70, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.playlist[_currentIndex]['title'],
                    style: TextStyle(color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, color: Colors.white70, size: 16),
                SizedBox(width: 8),
                Text(
                  '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.speed, color: Colors.white70, size: 16),
                SizedBox(width: 8),
                Text('سرعت: ${_playbackRate}x', style: TextStyle(color: Colors.white)),
              ],
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: Icon(Icons.skip_previous, color: Colors.white),
                  onPressed: _prevSong,
                ),
                IconButton(
                  icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white),
                  onPressed: _togglePlayPause,
                ),
                IconButton(
                  icon: Icon(Icons.skip_next, color: Colors.white),
                  onPressed: _nextSong,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParallaxBackground(String? imageUrl, Size size) {
    return AnimatedBuilder(
      animation: _bgAnimation,
      builder: (context, child) {
        final offset = _bgAnimation.value * 100;
        return Transform.translate(
          offset: Offset(offset * 0.3, offset * 0.1),
          child: Container(
            width: size.width + 100,
            height: size.height + 100,
            decoration: imageUrl != null
                ? BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(imageUrl),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.7), BlendMode.darken),
              ),
            )
                : BoxDecoration(color: Colors.grey[900]),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(color: Colors.black.withOpacity(0.4)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAlbumArt(String? u) {
    return ScaleTransition(
      scale: _albumArtAnimation,
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.purple.withOpacity(0.7), blurRadius: 25, spreadRadius: 3),
          ],
        ),
        child: ClipOval(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.black87, Colors.black],
              ),
            ),
            child: Center(
              child: Image.asset(
                'assets/images/logo.png',
                width: 200,
                height: 200,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSongInfo(Map<String, dynamic> song) {
    return FadeTransition(
      opacity: _controlsAnimation,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(_controlsAnimation),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
          child: Column(
            children: [
              Text(
                song['title'],
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, shadows: [
                  Shadow(blurRadius: 10, color: Colors.purple.withOpacity(0.8)),
                ]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (song['artist'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    song['artist'],
                    style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.8)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlider() {
    return FadeTransition(
      opacity: _controlsAnimation,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(_controlsAnimation),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
          child: Column(
            children: [
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8, disabledThumbRadius: 6),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                  activeTrackColor: Colors.purpleAccent,
                  inactiveTrackColor: Colors.grey[700],
                  thumbColor: Colors.white,
                ),
                child: Slider(
                  min: 0,
                  max: _duration.inSeconds.toDouble(),
                  value: _position.inSeconds.toDouble().clamp(0, _duration.inSeconds.toDouble()),
                  onChanged: (value) => _seekToSeconds(value.toInt()),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_formatDuration(_position), style: TextStyle(color: Colors.white70)),
                    Text(_formatDuration(_duration - _position), style: TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaybackRateControl() {
    return FadeTransition(
      opacity: _controlsAnimation,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(_controlsAnimation),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.speed, color: Colors.white70),
              SizedBox(width: 10),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    activeTrackColor: Colors.purpleAccent,
                    inactiveTrackColor: Colors.grey[700],
                  ),
                  child: Slider(
                    min: 0.5,
                    max: 2.0,
                    divisions: 6,
                    label: '${_playbackRate}x',
                    value: _playbackRate,
                    onChanged: (value) => _changePlaybackRate(value),
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('${_playbackRate}x', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    return FadeTransition(
      opacity: _controlsAnimation,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(_controlsAnimation),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildControlButton(icon: Icons.skip_previous, onPressed: _prevSong, size: 36),
              const SizedBox(width: 30),
              _buildControlButton(
                icon: _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                onPressed: _togglePlayPause,
                size: 70,
                isMain: true,
              ),
              const SizedBox(width: 30),
              _buildControlButton(icon: Icons.skip_next, onPressed: _nextSong, size: 36),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required double size,
    bool isMain = false,
  }) {
    return Container(
      decoration: isMain
          ? BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.purple.withOpacity(0.6), blurRadius: 20, spreadRadius: 5)],
      )
          : null,
      child: IconButton(
        iconSize: size,
        color: Colors.white,
        icon: Icon(icon),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildVolume() {
    return FadeTransition(
      opacity: _controlsAnimation,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(_controlsAnimation),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
          child: Row(
            children: [
              Icon(Icons.volume_down, color: Colors.white70),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    activeTrackColor: Colors.purpleAccent,
                    inactiveTrackColor: Colors.grey[700],
                  ),
                  child: Slider(
                    min: 0,
                    max: 1,
                    value: _volume,
                    onChanged: (value) {
                      if (!_disposed && mounted) setState(() => _volume = value);
                      _audioPlayer.setVolume(value);
                    },
                  ),
                ),
              ),
              Icon(Icons.volume_up, color: Colors.white70),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedTitle extends StatefulWidget {
  final String text;
  const _AnimatedTitle({required this.text});

  @override
  State<_AnimatedTitle> createState() => _AnimatedTitleState();
}

class _AnimatedTitleState extends State<_AnimatedTitle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
    _animation = Tween<Offset>(begin: const Offset(1, 0), end: const Offset(-1, 0))
        .animate(CurvedAnimation(parent: _controller, curve: Curves.linear));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _animation,
      child: Text(
        widget.text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [Shadow(blurRadius: 5, color: Colors.purple)],
        ),
      ),
    );
  }
}

class GlobalPlayerStatusPanel extends StatelessWidget {
  const GlobalPlayerStatusPanel({Key? key}) : super(key: key);

  String _formatDuration(Duration d) {
    return '${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final GlobalAudioPlayer globalPlayer = GlobalAudioPlayer();

    return ValueListenableBuilder<bool>(
      valueListenable: globalPlayer.isPlaying,
      builder: (context, isPlaying, child) {
        return ValueListenableBuilder<String>(
          valueListenable: globalPlayer.currentSongTitle,
          builder: (context, title, child) {
            return ValueListenableBuilder<Duration>(
              valueListenable: globalPlayer.currentPosition,
              builder: (context, position, child) {
                return ValueListenableBuilder<Duration>(
                  valueListenable: globalPlayer.totalDuration,
                  builder: (context, duration, child) {
                    return Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(isPlaying ? Icons.music_note : Icons.pause,
                                  color: Colors.white, size: 16),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  title.isNotEmpty ? title : 'هیچ آهنگی پخش نمی‌شود',
                                  style: TextStyle(color: Colors.white, fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          if (title.isNotEmpty)
                            Row(
                              children: [
                                Text(_formatDuration(position),
                                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                                Expanded(
                                  child: SliderTheme(
                                    data: SliderThemeData(
                                      trackHeight: 2,
                                      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
                                      activeTrackColor: Colors.purpleAccent,
                                      inactiveTrackColor: Colors.grey[700],
                                      thumbColor: Colors.white,
                                    ),
                                    child: Slider(
                                      min: 0,
                                      max: duration.inSeconds.toDouble(),
                                      value: position.inSeconds
                                          .toDouble()
                                          .clamp(0, duration.inSeconds.toDouble()),
                                      onChanged: (value) {
                                        globalPlayer.audioPlayer
                                            .seek(Duration(seconds: value.toInt()));
                                      },
                                    ),
                                  ),
                                ),
                                Text(_formatDuration(duration),
                                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                              ],
                            ),
                          if (title.isNotEmpty)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.skip_previous, color: Colors.white, size: 20),
                                  onPressed: globalPlayer.playPrevious,
                                ),
                                IconButton(
                                  icon: Icon(
                                    isPlaying ? Icons.pause : Icons.play_arrow,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  onPressed: globalPlayer.togglePlayPause,
                                ),
                                IconButton(
                                  icon: Icon(Icons.skip_next, color: Colors.white, size: 20),
                                  onPressed: globalPlayer.playNext,
                                ),
                              ],
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
