import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Represents a discovered Bluetooth device
class BluetoothDeviceItem {
  final String address;
  final String name;
  final BluetoothDevice? device;
  final int rssi;

  BluetoothDeviceItem({
    required this.address,
    required this.name,
    required this.device,
    this.rssi = 0,
  });

  String get displayName => name.isEmpty ? 'Unknown Device ($address)' : name;

  @override
  String toString() => 'BT($displayName, $address, rssi=$rssi)';
}

/// Manages Bluetooth device discovery, connection, and A2DP audio routing
/// using flutter_blue_plus.
class BluetoothService extends ChangeNotifier {
  final List<BluetoothDeviceItem> _devices = [];
  final List<BluetoothDeviceItem> _pairedDevices = [];
  bool _isScanning = false;
  BluetoothDeviceItem? _connectedDevice;
  StreamSubscription<List<ScanResult>>? _scanSubscription;

  List<BluetoothDeviceItem> get devices => List.unmodifiable(_devices);
  List<BluetoothDeviceItem> get pairedDevices => List.unmodifiable(_pairedDevices);
  bool get isScanning => _isScanning;
  BluetoothDeviceItem? get connectedDevice => _connectedDevice;

  /// Start scanning for nearby Bluetooth devices
  Future<void> startScan() async {
    _devices.clear();
    _isScanning = true;
    notifyListeners();

    try {
      // Cancel any existing scan first
      await stopScan();

      // Start scan and listen to results
      _scanSubscription = FlutterBluePlus.scanResults.listen(
        (results) {
          final updatedDevices = <BluetoothDeviceItem>[];

          for (final r in results) {
            // Skip if we already have this device with same/better RSSI
            final existingIndex = updatedDevices.indexWhere(
              (d) => d.address == r.device.remoteId.str,
            );
            if (existingIndex >= 0) {
              // Keep the one with better (higher) RSSI
              if (r.rssi > updatedDevices[existingIndex].rssi) {
                updatedDevices[existingIndex] = BluetoothDeviceItem(
                  address: r.device.remoteId.str,
                  name: r.device.advName,
                  device: r.device,
                  rssi: r.rssi,
                );
              }
            } else {
              updatedDevices.add(BluetoothDeviceItem(
                address: r.device.remoteId.str,
                name: r.device.advName,
                device: r.device,
                rssi: r.rssi,
              ));
            }
          }

          _devices.clear();
          _devices.addAll(updatedDevices);
          notifyListeners();
        },
        onError: (e) => debugPrint('[BluetoothService] scan error: $e'),
      );

      // Start scan
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));

      // Wait for scan to complete
      await Future.delayed(const Duration(seconds: 10));
      if (_isScanning) {
        await stopScan();
      }
    } catch (e) {
      debugPrint('[BluetoothService] startScan error: $e');
      _isScanning = false;
    }
    notifyListeners();
  }

  /// Stop scanning
  Future<void> stopScan() async {
    try {
      await _scanSubscription?.cancel();
      _scanSubscription = null;
      await FlutterBluePlus.stopScan();
    } catch (e) {
      debugPrint('[BluetoothService] stopScan error: $e');
    }
    _isScanning = false;
    notifyListeners();
  }

  /// Connect to a Bluetooth device by address
  Future<bool> connect(String address) async {
    try {
      final scanResult = FlutterBluePlus.lastScanResults
          .firstWhere((r) => r.device.remoteId.str == address, orElse: () {
        return ScanResult(
          device: BluetoothDevice.fromId(address),
          advertisementData: AdvertisementData(
            advName: '',
            txPowerLevel: null,
            appearance: null,
            connectable: false,
            manufacturerData: {},
            serviceData: {},
            serviceUuids: [],
          ),
          rssi: 0,
          timeStamp: DateTime.now(),
        );
      });

      final btDevice = scanResult.device;
      await btDevice.connect(license: License.nonprofit, mtu: 512);

      _connectedDevice = BluetoothDeviceItem(
        address: address,
        name: btDevice.platformName,
        device: btDevice,
      );

      // Observe connection state changes
      btDevice.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _connectedDevice = null;
          notifyListeners();
        }
      });

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[BluetoothService] connect error: $e');
      return false;
    }
  }

  /// Disconnect from the currently connected device
  Future<void> disconnect() async {
    if (_connectedDevice?.device != null) {
      try {
        await _connectedDevice!.device!.disconnect();
      } catch (e) {
        debugPrint('[BluetoothService] disconnect error: $e');
      }
    }
    _connectedDevice = null;
    notifyListeners();
  }

  /// Unpair a device (remove pairing)
  Future<void> unpair(String address) async {
    try {
      final scanResult = FlutterBluePlus.lastScanResults
          .firstWhere((r) => r.device.remoteId.str == address, orElse: () {
        return ScanResult(
          device: BluetoothDevice.fromId(address),
          advertisementData: AdvertisementData(
            advName: '',
            txPowerLevel: null,
            appearance: null,
            connectable: false,
            manufacturerData: {},
            serviceData: {},
            serviceUuids: [],
          ),
          rssi: 0,
          timeStamp: DateTime.now(),
        );
      });
      await scanResult.device.disconnect();
      _devices.removeWhere((d) => d.address == address);
      _pairedDevices.removeWhere((d) => d.address == address);
      notifyListeners();
    } catch (e) {
      debugPrint('[BluetoothService] unpair error: $e');
    }
  }

  /// Get paired devices (reads system bond state)
  Future<List<BluetoothDeviceItem>> getPairedDevices() async {
    try {
      final bonded = await FlutterBluePlus.bondedDevices;
      _pairedDevices.clear();
      for (final device in bonded) {
        _pairedDevices.add(BluetoothDeviceItem(
          address: device.remoteId.str,
          name: device.platformName,
          device: device,
        ));
      }
      notifyListeners();
      return List.unmodifiable(_pairedDevices);
    } catch (e) {
      debugPrint('[BluetoothService] getPairedDevices error: $e');
      return [];
    }
  }

  /// Check Bluetooth adapter state
  Future<BluetoothAdapterState> getBluetoothState() async {
    try {
      return await FlutterBluePlus.adapterState.first;
    } catch (e) {
      return BluetoothAdapterState.unknown;
    }
  }

  /// Request A2DP connection for audio streaming (Android only)
  Future<bool> requestA2dpConnection(String address) async {
    try {
      return await connect(address);
    } catch (e) {
      debugPrint('[BluetoothService] A2DP connection error: $e');
      return false;
    }
  }

  @override
  void dispose() {
    stopScan();
    disconnect();
    super.dispose();
  }
}
