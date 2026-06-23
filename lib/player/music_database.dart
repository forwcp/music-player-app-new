import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class MusicDatabase extends ChangeNotifier {
  final List<Map<String, dynamic>> _songs = [];
  List<Map<String, dynamic>> get songs => List.unmodifiable(_songs);

  Future<void> scanMusic() async {
    _songs.clear();

    if (!kIsWeb && Platform.isAndroid) {
      final audioStatus = await Permission.audio.status;
      if (audioStatus.isDenied || audioStatus.isPermanentlyDenied) {
        final result = await Permission.audio.request();
        if (result.isDenied || result.isPermanentlyDenied) {
          debugPrint('[MusicDatabase] Audio permission denied');
          notifyListeners();
          return;
        }
      }
    }

    final directories = <String>[];

    if (!kIsWeb && Platform.isAndroid) {
      final standardDirs = [
        '/storage/emulated/0/Music',
        '/storage/emulated/0/Download',
        '/storage/emulated/0/Podcasts',
      ];
      
      for (final dirPath in standardDirs) {
        final dir = Directory(dirPath);
        if (dir.existsSync() && !directories.contains(dirPath)) {
          directories.add(dirPath);
        }
      }
    }

    for (final dirPath in directories) {
      final dir = Directory(dirPath);
      if (dir.existsSync()) {
        _scanDirectory(dir, depth: 0);
      }
    }

    _songs.sort((a, b) => a['title'].compareTo(b['title']));
    debugPrint('[MusicDatabase] Found ${_songs.length} songs');
    notifyListeners();
  }

  void _scanDirectory(Directory dir, {int depth = 0}) {
    if (depth > 5) return;
    
    try {
      final entities = dir.listSync(recursive: false);
      for (final entity in entities) {
        if (entity is File && _isAudioFile(entity.path)) {
          final name = entity.path.split(Platform.pathSeparator).last;
          _songs.add({
            'path': entity.path,
            'title': _extractTitle(name),
            'artist': 'Unknown Artist',
            'album': 'Unknown Album',
            'duration': 0,
          });
        } else if (entity is Directory) {
          _scanDirectory(entity, depth: depth + 1);
        }
      }
    } catch (e) {
      debugPrint('[MusicDatabase] Error scanning ${dir.path}: $e');
    }
  }

  bool _isAudioFile(String path) {
    final ext = path.toLowerCase().split('.').last;
    return ext == 'mp3' || ext == 'flac' || ext == 'wav' || 
           ext == 'aac' || ext == 'ogg' || ext == 'm4a' || 
           ext == 'wma' || ext == 'opus' || ext == 'webm';
  }

  String _extractTitle(String filename) {
    return filename.replaceAll(RegExp(r'\.[^.]+$'), '');
  }
}
