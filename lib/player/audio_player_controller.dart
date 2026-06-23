import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:just_audio/just_audio.dart';

enum DeviceType { dlna, bluetooth }

class CastDevice {
  final String id;
  final String name;
  final String address;
  final DeviceType type;
  final String icon;
  final Color color;

  CastDevice({
    required this.id,
    required this.name,
    required this.address,
    required this.type,
    required this.icon,
    required this.color,
  });
}

class AudioPlayerController extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  bool _isRemoteCast = false;
  CastDevice? _castDevice;

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
  bool get isRemoteCast => _isRemoteCast;
  CastDevice? get castDevice => _castDevice;

  AudioPlayerController() {
    _player.positionStream.listen((pos) {
      notifyListeners();
    });

    _player.playingStream.listen((playing) {
      notifyListeners();
    });

    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        if (hasNext) {
          playNext();
        } else {
          _player.stop();
          notifyListeners();
        }
      }
    });

    _player.errorStream.listen((error) {
      debugPrint('[AudioPlayer] Error: $error');
    });
  }

  void loadPlaylist(List<Map<String, dynamic>> songs) {
    _playlist = songs;
    notifyListeners();
  }

  Future<void> playSong(int index) async {
    if (index < 0 || index >= _playlist.length) {
      debugPrint('[AudioPlayer] Invalid index: $index, playlist length: ${_playlist.length}');
      return;
    }

    _currentIndex = index;
    final song = _playlist[index];
    final path = song['path'];

    debugPrint('[AudioPlayer] === Starting playSong ===');
    debugPrint('[AudioPlayer] Index: $index');
    debugPrint('[AudioPlayer] Title: ${song['title']}');
    debugPrint('[AudioPlayer] Path: $path');
    debugPrint('[AudioPlayer] File exists: ${_fileExists(path)}');

    try {
      await _player.stop();
      debugPrint('[AudioPlayer] Stopped previous playback');

      await _player.setFilePath(path);
      debugPrint('[AudioPlayer] setFilePath succeeded');

      await _player.play();
      debugPrint('[AudioPlayer] play() succeeded, isPlaying: ${_player.playing}');

      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('[AudioPlayer] ERROR: $e');
      debugPrint('[AudioPlayer] Stack: $stackTrace');
      notifyListeners();
    }
  }

  bool _fileExists(String path) {
    try {
      return File(path).existsSync();
    } catch (e) {
      return false;
    }
  }

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
    notifyListeners();
  }

  Future<void> playNext() async {
    if (hasNext) {
      await playSong(_currentIndex + 1);
    }
  }

  Future<void> playPrevious() async {
    if (hasPrevious) {
      await playSong(_currentIndex - 1);
    }
  }

  Future<void> seekTo(Duration d) async {
    await _player.seek(d);
    notifyListeners();
  }

  Future<void> setVolume(double v) async {
    _player.setVolume(v);
    notifyListeners();
  }

  void setRemoteCast(CastDevice device) {
    _isRemoteCast = true;
    _castDevice = device;
    debugPrint('[AudioPlayer] Casting to: ${device.name} (${device.address})');
    notifyListeners();
  }

  void disconnectCast() {
    _isRemoteCast = false;
    _castDevice = null;
    debugPrint('[AudioPlayer] Cast disconnected');
    notifyListeners();
  }

  Future<void> remotePlay() async {
    debugPrint('[AudioPlayer] Remote play requested');
    notifyListeners();
  }

  Future<void> remotePause() async {
    debugPrint('[AudioPlayer] Remote pause requested');
    notifyListeners();
  }

  Future<void> remoteSeek(Duration d) async {
    debugPrint('[AudioPlayer] Remote seek to $d');
    notifyListeners();
  }

  Future<void> remoteSetVolume(double v) async {
    debugPrint('[AudioPlayer] Remote set volume to $v');
    notifyListeners();
  }

  Future<void> remotePlaySong(int index) async {
    debugPrint('[AudioPlayer] Remote play song index $index');
    _currentIndex = index;
    notifyListeners();
  }

  Future<void> remotePlayNext() async {
    debugPrint('[AudioPlayer] Remote play next');
    if (hasNext) {
      _currentIndex++;
      notifyListeners();
    }
  }

  Future<void> remotePlayPrevious() async {
    debugPrint('[AudioPlayer] Remote play previous');
    if (hasPrevious) {
      _currentIndex--;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
