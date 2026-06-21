import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_player_app/player/music_database.dart';
import 'package:music_player_app/services/dlna_service.dart';

class AudioPlayerController extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  final DlnaService _dlna = DlnaService();

  List<Map<String, dynamic>> _playlist = [];
  List<Map<String, dynamic>> get playlist => _playlist;

  int _currentIndex = -1;
  int get currentIndex => _currentIndex;

  String get currentTitle =>
      _currentIndex >= 0 && _currentIndex < _playlist.length
          ? _playlist[_currentIndex]['title']
          : 'No Track';

  String get currentArtist =>
      _currentIndex >= 0 && _currentIndex < _playlist.length
          ? _playlist[_currentIndex]['artist']
          : 'Unknown Artist';

  String get currentPath =>
      _currentIndex >= 0 && _currentIndex < _playlist.length
          ? _playlist[_currentIndex]['path']
          : '';

  Duration get position => _player.position;
  Duration get duration => _player.duration ?? Duration.zero;

  bool get isPlaying => _player.playing;
  bool get hasNext => _currentIndex < _playlist.length - 1;
  bool get hasPrevious => _currentIndex > 0;
  double get volume => _player.volume;

  AudioPlayerController() {
    _dlna.addListener(_onDlnaChanged);

    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed && _currentIndex < _playlist.length - 1) {
        playNext();
      } else if (state == ProcessingState.completed) {
        _player.stop();
        notifyListeners();
      }
    });

    _player.positionStream.listen((pos) => notifyListeners());
    _player.playingStream.listen((playing) => notifyListeners());
  }

  void _onDlnaChanged() {
    if (_dlna.isConnected && _currentIndex >= 0) {
      _castCurrentSongToDlna();
    }
    notifyListeners();
  }

  // ── Playlist ───────────────────────────────────────────────

  Future<void> loadPlaylist(MusicDatabase db) async {
    _playlist = db.songs;
    notifyListeners();
  }

  // ── Playback (transparent DLNA forwarding) ─────────────────

  Future<void> playSong(int index) async {
    if (index < 0 || index >= _playlist.length) return;
    _currentIndex = index;
    notifyListeners();

    if (_dlna.isConnected) {
      await _dlna.castSong(this, index);
    } else {
      final song = _playlist[index];
      await _player.setFilePath(song['path']);
      await _player.play();
    }
  }

  Future<void> play() async {
    if (_dlna.isConnected) {
      await _dlna.remotePlay();
    } else {
      await _player.play();
    }
    notifyListeners();
  }

  Future<void> pause() async {
    if (_dlna.isConnected) {
      await _dlna.remotePause();
    } else {
      await _player.pause();
    }
    notifyListeners();
  }

  Future<void> togglePlayPause() async {
    if (_currentIndex < 0) {
      if (_playlist.isNotEmpty) {
        await playSong(0);
      }
      return;
    }
    if (_player.playing) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> seekTo(Duration position) async {
    if (_dlna.isConnected) {
      await _dlna.remoteSeek(position);
    } else {
      await _player.seek(position);
    }
    notifyListeners();
  }

  Future<void> playNext() async {
    if (_dlna.isConnected) {
      await _dlna.remoteNext();
    } else if (_currentIndex < _playlist.length - 1) {
      await playSong(_currentIndex + 1);
    }
  }

  Future<void> playPrevious() async {
    if (_dlna.isConnected) {
      await _dlna.remotePrevious();
    } else if (_currentIndex > 0) {
      await playSong(_currentIndex - 1);
    } else if (_player.position.inMilliseconds > 3000) {
      await seekTo(Duration.zero);
    }
  }

  Future<void> setVolume(double v) async {
    if (_dlna.isConnected) {
      final vol = (v * 100).round().clamp(0, 100);
      await _dlna.remoteSetVolume(vol);
    } else {
      await _player.setVolume(v);
    }
    notifyListeners();
  }

  Future<void> _castCurrentSongToDlna() async {
    if (_dlna.isConnected && _currentIndex >= 0) {
      await _dlna.castSong(this, _currentIndex);
    }
  }

  @override
  void dispose() {
    _dlna.dispose();
    _player.dispose();
    super.dispose();
  }
}
