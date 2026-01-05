import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class BackgroundAudioControl extends StatefulWidget {
  const BackgroundAudioControl({super.key});

  @override
  State<BackgroundAudioControl> createState() => _BackgroundAudioControlState();
}

class _BackgroundAudioControlState extends State<BackgroundAudioControl> {
  late AudioPlayer _player;
  bool _isPlaying = false;
  bool _isMuted = false;
  final String _demoAudioUrl = 'https://cdn.pixabay.com/audio/2022/05/27/audio_1808fbf07a.mp3';

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _player.setReleaseMode(ReleaseMode.loop);
  }

  Future<void> _playMusic() async {
    try {
      // First try to play from assets
      try {
         await _player.play(AssetSource('sounds/theme_song.mp3'));
      } catch (e) {
         // Silently fall back to demo URL if asset missing.
         // 'e' here might be the "Asset not found" PlatformException.
         // We don't need to log heavily.
         await _player.play(UrlSource(_demoAudioUrl));
      }
      
      setState(() {
        _isPlaying = true;
      });
    } catch (e) {
      // General playback error (network etc)
      debugPrint('Warning: Audio playback failed. (${e.toString().substring(0, 50)}...)');
      setState(() {
        _isPlaying = false; // Reset state if failed
      });
    }
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      await _playMusic();
    }
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  Future<void> _toggleMute() async {
    if (_isMuted) {
      await _player.setVolume(1.0);
    } else {
      await _player.setVolume(0.0);
    }
    setState(() {
      _isMuted = !_isMuted;
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              _isPlaying ? Icons.music_note : Icons.music_off,
              color: _isPlaying ? Colors.greenAccent : Colors.white70,
              size: 20,
            ),
            onPressed: _togglePlay,
            tooltip: _isPlaying ? 'Pause Music' : 'Play Theme Song',
          ),
          if (_isPlaying)
            IconButton(
              icon: Icon(
                _isMuted ? Icons.volume_off : Icons.volume_up,
                color: Colors.white70,
                size: 20,
              ),
              onPressed: _toggleMute,
              tooltip: _isMuted ? 'Unmute' : 'Mute',
            ),
        ],
      ),
    );
  }
}
