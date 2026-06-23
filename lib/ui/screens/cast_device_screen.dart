import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:music_player_app/player/audio_player_controller.dart';
import 'package:music_player_app/player/cast_manager.dart';
import 'package:music_player_app/ui/theme/app_theme.dart';

class CastDeviceScreen extends StatefulWidget {
  const CastDeviceScreen({super.key});

  @override
  State<CastDeviceScreen> createState() => _CastDeviceScreenState();
}

class _CastDeviceScreenState extends State<CastDeviceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CastManager>().scanDevices();
    });
  }

  @override
  Widget build(BuildContext context) {
    final castManager = context.watch<CastManager>();
    final controller = context.watch<AudioPlayerController>();

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0D0D),
        appBar: AppBar(
          title: const Text('Select Device'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Column(
          children: [
            // Tabs
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: _DeviceTab(
                    label: 'DLNA',
                    icon: Icons.tv,
                    color: const Color(0xFF667eea),
                    isActive: true,
                    onTap: () {},
                  ),
                ),
                Expanded(
                  child: _DeviceTab(
                    label: 'Bluetooth',
                    icon: Icons.bluetooth,
                    color: const Color(0xFF56ccf2),
                    isActive: false,
                    onTap: () {},
                  ),
                ),
              ],
            ),
            const Divider(height: 1, color: Color(0xFF2D2D3F)),
            
            // Scanning or Devices
            if (castManager.isScanning)
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Scanning devices...', style: TextStyle(color: Color(0xFF8888A0))),
                    ],
                  ),
                ),
              )
            else if (castManager.devices.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.white.withValues(alpha: 0.2)),
                      const SizedBox(height: 16),
                      Text('No devices found', style: TextStyle(color: Color(0xFF8888A0), fontSize: 16)),
                      const SizedBox(height: 8),
                      Text('Make sure your devices are on the same network', style: TextStyle(color: Color(0xFF8888A0), fontSize: 12)),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: castManager.devices.length,
                  itemBuilder: (context, index) {
                    final device = castManager.devices[index];
                    return _DeviceCard(device: device, onConnect: () {
                      controller.setRemoteCast(device);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Connected to ${device.name}'),
                          backgroundColor: device.color,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    });
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DeviceTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isActive;
  final VoidCallback onTap;

  const _DeviceTab({
    required this.label,
    required this.icon,
    required this.color,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? color : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isActive ? color : const Color(0xFF8888A0)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: isActive ? color : const Color(0xFF8888A0))),
          ],
        ),
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  final CastDevice device;
  final VoidCallback onConnect;

  const _DeviceCard({required this.device, required this.onConnect});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: device.color.withValues(alpha: 0.3)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: device.color.withValues(alpha: 0.2),
          child: Icon(
            device.type == DeviceType.dlna ? Icons.tv : Icons.bluetooth,
            color: device.color,
          ),
        ),
        title: Text(
          device.name,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Chip(
              label: Text(
                device.type == DeviceType.dlna ? 'DLNA' : 'Bluetooth',
                style: const TextStyle(fontSize: 10, color: Colors.white),
              ),
              backgroundColor: device.color,
              padding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const SizedBox(height: 4),
            Text(device.address, style: const TextStyle(color: Color(0xFF8888A0), fontSize: 12)),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: onConnect,
          style: ElevatedButton.styleFrom(
            backgroundColor: device.color,
            foregroundColor: Colors.white,
            minimumSize: const Size(60, 30),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          ),
          child: const Text('Connect', style: TextStyle(fontSize: 12)),
        ),
      ),
    );
  }
}
