import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:music_player_app/player/audio_player_controller.dart';
import 'package:music_player_app/player/music_database.dart';
import 'package:music_player_app/ui/screens/home_screen.dart';
import 'package:music_player_app/ui/screens/player_screen.dart';
import 'package:music_player_app/ui/screens/cast_device_screen.dart';
import 'package:music_player_app/ui/theme/app_theme.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class CastManager extends ChangeNotifier {
  List<CastDevice> _devices = [];
  List<CastDevice> get devices => List.unmodifiable(_devices);
  
  bool _isScanning = false;
  bool get isScanning => _isScanning;

  Future<void> scanDevices() async {
    _isScanning = true;
    _devices.clear();
    notifyListeners();

    // Simulate DLNA scan
    await Future.delayed(const Duration(seconds: 2));
    _devices.add(CastDevice(
      id: 'dlna-living-room-tv',
      name: 'Living Room TV',
      address: '192.168.1.100',
      type: DeviceType.dlna,
      icon: 'tv',
      color: const Color(0xFF667eea),
    ));

    // Simulate Bluetooth scan
    await Future.delayed(const Duration(seconds: 1));
    _devices.add(CastDevice(
      id: 'bt-speaker-pro',
      name: 'Speaker Pro',
      address: 'AA:BB:CC:DD:EE:FF',
      type: DeviceType.bluetooth,
      icon: 'bluetooth',
      color: const Color(0xFF56ccf2),
    ));

    _isScanning = false;
    notifyListeners();
  }

  void removeDevice(String deviceId) {
    _devices.removeWhere((d) => d.id == deviceId);
    notifyListeners();
  }

  void clearAllDevices() {
    _devices.clear();
    notifyListeners();
  }
}
