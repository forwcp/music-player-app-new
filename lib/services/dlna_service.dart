import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dlna_dart/dlna.dart';
import 'package:dlna_dart/xmlParser.dart';
import 'package:music_player_app/player/audio_player_controller.dart';

/// Represents a discovered DLNA render device
class DlnaDevice {
  final String name;
  final String urlBase;
  final String deviceType;

  DlnaDevice({
    required this.name,
    required this.urlBase,
    required this.deviceType,
  });

  @override
  String toString() => 'DLNA($name, $deviceType)';
}

/// DLNA service — transparent proxy mode.
/// All App UI controls (play/pause/seek/volume/next/prev) are forwarded
/// to the DLNA device automatically when connected.
class DlnaService extends ChangeNotifier {
  final List<DlnaDevice> _devices = [];
  DLNADevice? _selectedDevice;
  DlnaDevice? _selectedDeviceInfo;
  DLNAManager? _manager;
  DeviceManager? _deviceManager;
  Timer? _scanTimer;
  bool _isCasting = false;

  List<DlnaDevice> get devices => List.unmodifiable(_devices);
  DlnaDevice? get connectedDevice => _selectedDeviceInfo;
  bool get isConnected => _isCasting;

  // ── Discovery ──────────────────────────────────────────────

  Future<void> startScan() async {
    _devices.clear();
    _isCasting = false;
    _selectedDevice = null;
    _selectedDeviceInfo = null;
    notifyListeners();

    try {
      _manager = DLNAManager();
      _deviceManager = await _manager!.start();

      _deviceManager!.devices.stream.listen((map) {
        _devices.clear();
        map.forEach((urlBase, dlnaDevice) {
          if (dlnaDevice.info.deviceType.contains('MediaRenderer') ||
              dlnaDevice.info.friendlyName.isNotEmpty) {
            _devices.add(DlnaDevice(
              name: dlnaDevice.info.friendlyName,
              urlBase: urlBase,
              deviceType: _classifyDeviceType(dlnaDevice.info.deviceType),
            ));
          }
        });
        notifyListeners();
      });

      _scanTimer = Timer(const Duration(seconds: 10), () {
        stopScan();
      });
    } catch (e) {
      print('DLNA scan error: $e');
    }
  }

  void stopScan() {
    _scanTimer?.cancel();
    if (_manager != null) {
      try {
        _manager!.stop();
      } catch (e) {
        print('DLNA stop error: $e');
      }
      _manager = null;
      _deviceManager = null;
    }
  }

  // ── Connect / Disconnect ───────────────────────────────────

  Future<void> selectDevice(DlnaDevice device) async {
    if (_deviceManager == null) return;
    _selectedDeviceInfo = device;
    final found = _deviceManager!.deviceList[device.urlBase];
    if (found != null) {
      _selectedDevice = found;
      _isCasting = true;
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    if (_selectedDevice != null) {
      try {
        await _selectedDevice!.stop();
      } catch (e) {
        print('DLNA disconnect error: $e');
      }
    }
    _isCasting = false;
    _selectedDevice = null;
    _selectedDeviceInfo = null;
    notifyListeners();
  }

  // ── Transparent forwarding ─────────────────────────────────

  Future<void> castSong(AudioPlayerController controller, int index) async {
    if (_selectedDevice == null || !_isCasting) return;
    try {
      if (index < 0 || index >= controller.playlist.length) return;
      final song = controller.playlist[index];
      final filePath = song['path'] as String;
      final uri = Uri.file(filePath);
      final title = song['title'] as String? ?? 'Unknown';

      final data = XmlText.setPlayURLXml(
        uri.toString(),
        title: title,
        type: PlayType.Audio,
      );
      await _selectedDevice!.request('SetAVTransportURI', utf8.encode(data));
      await _selectedDevice!.play();
    } catch (e) {
      print('DLNA castSong error: $e');
    }
  }

  Future<void> remotePlay() async {
    if (_selectedDevice == null) return;
    try {
      await _selectedDevice!.play();
    } catch (e) {
      print('DLNA play error: $e');
    }
  }

  Future<void> remotePause() async {
    if (_selectedDevice == null) return;
    try {
      await _selectedDevice!.pause();
    } catch (e) {
      print('DLNA pause error: $e');
    }
  }

  Future<void> remoteStop() async {
    if (_selectedDevice == null) return;
    try {
      await _selectedDevice!.stop();
    } catch (e) {
      print('DLNA stop error: $e');
    }
  }

  Future<void> remoteSeek(Duration position) async {
    if (_selectedDevice == null) return;
    try {
      final seekStr = await _selectedDevice!.seekByCurrent('', position.inSeconds);
      await _selectedDevice!.seek(seekStr);
    } catch (e) {
      print('DLNA seek error: $e');
    }
  }

  Future<void> remoteSetVolume(int volume) async {
    if (_selectedDevice == null) return;
    try {
      await _selectedDevice!.volume(volume);
    } catch (e) {
      print('DLNA volume error: $e');
    }
  }

  Future<void> remoteNext() async {
    if (_selectedDevice == null) return;
    try {
      await _selectedDevice!.next();
    } catch (e) {
      print('DLNA next error: $e');
    }
  }

  Future<void> remotePrevious() async {
    if (_selectedDevice == null) return;
    try {
      await _selectedDevice!.previous();
    } catch (e) {
      print('DLNA previous error: $e');
    }
  }

  String _classifyDeviceType(String type) {
    if (type.contains('MediaServer')) return '🖥 Server';
    if (type.contains('MediaRenderer') || type.contains('Speaker')) return '🔊 Speaker';
    if (type.contains('Display')) return '📺 Display';
    if (type.contains('TV')) return '📺 TV';
    if (type.contains('Receiver')) return '🔈 Receiver';
    return '📡 Device';
  }

  @override
  void dispose() {
    stopScan();
    super.dispose();
  }
}
