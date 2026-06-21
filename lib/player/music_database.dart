import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class MusicDatabase extends ChangeNotifier {
  final List<Map<String, dynamic>> _songs = [];
  List<Map<String, dynamic>> get songs => _songs;

  Future<void> scanMusic() async {
    _songs.clear();
    final directories = <String>[];

    // Scan external storage on Android
    if (!kIsWeb && Platform.isAndroid) {
      final musicDir = Directory('/storage/emulated/0/Music');
      if (musicDir.existsSync()) directories.add(musicDir.path);
      final downloadDir = Directory('/storage/emulated/0/Download');
      if (downloadDir.existsSync()) directories.add(downloadDir.path);
    }

    // Scan documents directory for local files
    final appDir = await getApplicationDocumentsDirectory();
    directories.add(appDir.path);

    // Also scan common music folders on Windows
    if (!kIsWeb && Platform.isWindows) {
      final username = Platform.environment['USERNAME'];
      if (username != null) {
        final musicFolder = Directory('C:/Users/$username/Music');
        if (musicFolder.existsSync()) directories.add(musicFolder.path);
      }
    }

    for (final dirPath in directories) {
      final dir = Directory(dirPath);
      if (!dir.existsSync()) continue;
      _scanDirectory(dir);
    }

    notifyListeners();
  }

  void _scanDirectory(Directory dir) {
    dir.listSync().forEach((entity) {
      if (entity is File && _isAudioFile(entity.path)) {
        final name = entity.path.split('/').last.split(r'\').last;
        _songs.add({
          'path': entity.path,
          'title': _extractTitle(name),
          'artist': 'Unknown Artist',
          'album': 'Unknown Album',
          'duration': 0,
        });
      } else if (entity is Directory) {
        _scanDirectory(entity);
      }
    });
  }

  bool _isAudioFile(String path) {
    final ext = path.toLowerCase();
    return ext.endsWith('.mp3') ||
        ext.endsWith('.flac') ||
        ext.endsWith('.wav') ||
        ext.endsWith('.aac') ||
        ext.endsWith('.ogg') ||
        ext.endsWith('.m4a') ||
        ext.endsWith('.wma');
  }

  String _extractTitle(String filename) {
    return filename.replaceAll(RegExp(r'\.[^.]+$'), '');
  }
}
