import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:music_player_app/player/audio_player_controller.dart';
import 'package:music_player_app/services/dlna_service.dart';
import 'package:music_player_app/ui/theme/app_theme.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _coverScale;
  late Animation<double> _coverShadow;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      reverseDuration: const Duration(milliseconds: 300),
    );
    _coverScale = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );
    _coverShadow = Tween<double>(begin: 0.2, end: 0.6).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _updateAnimation(bool playing) {
    if (playing) {
      _animController.forward();
    } else {
      _animController.reverse();
    }
  }

  /// Show the DLNA device picker as a modal bottom sheet
  Future<void> _showDlnaPicker(BuildContext context) async {
    final dlnaService = DlnaService();

    // Start scanning
    await dlnaService.startScan();

    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (innerCtx, setInnerState) {
            return Consumer<DlnaService>(
              builder: (context, svc, _) {
                final isConnected = svc.isConnected;
                final connectedName = isConnected
                    ? svc.connectedDevice!.name
                    : null;

                return Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isConnected
                                ? 'Casting to $connectedName'
                                : 'Cast to Device',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isConnected)
                            IconButton(
                              icon: const Icon(Icons.close_rounded, color: Colors.white),
                              onPressed: () async {
                                await svc.disconnect();
                                setInnerState(() {});
                                // Re-sync with provider
                                // DLNA service notifies listeners internally
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isConnected
                            ? 'Tap a device to switch, or disconnect above'
                            : 'Scanning for nearby DLNA devices...',
                        style: const TextStyle(
                          color: Color(0xFF8888A0),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Device list
                      SizedBox(
                        height: 280,
                        child: svc.devices.isEmpty
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation(Color(0xFF667eea)),
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      'Searching...',
                                      style: TextStyle(color: Color(0xFF8888A0)),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                itemCount: svc.devices.length,
                                itemBuilder: (context, index) {
                                  final device = svc.devices[index];
                                  final isSelected = isConnected &&
                                      svc.connectedDevice!.name == device.name;
                                  return ListTile(
                                    leading: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        gradient: isSelected
                                            ? AppTheme.primaryGradient
                                            : null,
                                        color: isSelected ? null : const Color(0xFF0D0D0D),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Center(
                                        child: Icon(
                                          isSelected
                                              ? Icons.cast_connected_rounded
                                              : Icons.cast_rounded,
                                          color: isSelected
                                              ? Colors.white
                                              : const Color(0xFF8888A0),
                                          size: 22,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      device.name,
                                      style: TextStyle(
                                        color: isSelected
                                            ? const Color(0xFF667eea)
                                            : Colors.white,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                    subtitle: Text(
                                      device.deviceType,
                                      style: const TextStyle(color: Color(0xFF8888A0)),
                                    ),
                                    onTap: () async {
                                      if (isSelected) return;
                                      await dlnaService.selectDevice(device);
                                      // Notify the global controller too
                                      // DLNA service notifies listeners internally
                                      setInnerState(() {});
                                      // Close after connecting
                                      await Future.delayed(const Duration(milliseconds: 500));
                                      if (mounted) Navigator.pop(ctx);
                                    },
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AudioPlayerController>();

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0D0D),
        body: SafeArea(
          child: Column(
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down_rounded,
                          color: Colors.white, size: 32),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      'Now Playing',
                      style: TextStyle(
                          color: Color(0xFF8888A0),
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                    IconButton(
                      icon: const Icon(Icons.queue_music_rounded,
                          color: Colors.white),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),

              // Album Art
              Expanded(
                flex: 3,
                child: Center(
                  child: AnimatedBuilder(
                    animation: controller,
                    builder: (context, child) {
                      _updateAnimation(controller.isPlaying);
                      return Transform.scale(
                        scale: _coverScale.value,
                        child: Container(
                          width: 280,
                          height: 280,
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: const BorderRadius.all(Radius.circular(24)),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF667eea).withValues(alpha:_coverShadow.value),
                                blurRadius: 40,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              Icons.music_note_rounded,
                              size: 80,
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Song Info
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                child: Column(
                  children: [
                    Text(
                      controller.currentTitle,
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 24),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      controller.currentArtist,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontSize: 16,
                        color: const Color(0xFF8888A0),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Progress Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    AnimatedBuilder(
                      animation: controller,
                      builder: (context, _) {
                        final pos = controller.position;
                        final dur = controller.duration;
                        final percent = dur.inMilliseconds > 0
                            ? pos.inMilliseconds / dur.inMilliseconds
                            : 0.0;

                        return Column(
                          children: [
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 4,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                                overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                              ),
                              child: Slider(
                                value: percent.clamp(0.0, 1.0),
                                onChanged: (v) {
                                  controller.seekTo(
                                    Duration(milliseconds: (v * dur.inMilliseconds).toInt()),
                                  );
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(_formatDuration(pos),
                                      style: const TextStyle(color: Color(0xFF8888A0), fontSize: 12)),
                                  Text(_formatDuration(dur),
                                      style: const TextStyle(color: Color(0xFF8888A0), fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),

              // ── DLNA Cast Status Bar ───────────────────────────────
              Consumer<DlnaService>(
                builder: (context, dlna, _) {
                  if (!dlna.isConnected) {
                    // Cast button — tap opens device picker
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => _showDlnaPicker(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFF2D2D3F), width: 1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.cast_rounded,
                                    color: Color(0xFF8888A0), size: 20),
                                const SizedBox(width: 8),
                                const Text(
                                  'Cast to Device',
                                  style: TextStyle(
                                    color: Color(0xFF8888A0),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  } else {
                    // Connected — show status + controls
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 32),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.cast_connected_rounded,
                                color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Casting to ${dlna.connectedDevice!.name}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Play/Pause (DLNA)
                            IconButton(
                              icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
                              onPressed: () => controller.play(),
                            ),
                            IconButton(
                              icon: const Icon(Icons.pause_rounded, color: Colors.white, size: 22),
                              onPressed: () => controller.pause(),
                            ),
                            // Stop
                            IconButton(
                              icon: const Icon(Icons.stop_rounded, color: Colors.white, size: 22),
                              onPressed: () async {
                                final svc = context.read<DlnaService>();
                                await svc.remoteStop();
                              },
                            ),
                            // Disconnect
                            IconButton(
                              icon: Icon(Icons.close_rounded, color: Colors.white.withValues(alpha: 0.7), size: 20),
                              onPressed: () async {
                                await dlna.disconnect();
                                // DLNA service notifies listeners internally
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                },
              ),

              // Controls
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.shuffle_rounded,
                          color: Color(0xFF8888A0), size: 28),
                      onPressed: () {},
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.skip_previous_rounded,
                          color: Colors.white, size: 40),
                      onPressed: controller.hasPrevious
                          ? () => controller.playPrevious()
                          : null,
                    ),
                    const SizedBox(width: 16),
                    // Play/Pause Button
                    Container(
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF667eea).withValues(alpha: 0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: AnimatedBuilder(
                          animation: controller,
                          builder: (context, _) {
                            return Icon(
                              controller.isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              size: 48,
                              color: Colors.white,
                            );
                          },
                        ),
                        onPressed: () => controller.togglePlayPause(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.skip_next_rounded,
                          color: Colors.white, size: 40),
                      onPressed: controller.hasNext
                          ? () => controller.playNext()
                          : null,
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.repeat_rounded,
                          color: Color(0xFF8888A0), size: 28),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),

              // Volume
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.volume_down_rounded,
                        color: Color(0xFF8888A0), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AnimatedBuilder(
                        animation: controller,
                        builder: (context, _) {
                          return SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 2,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                            ),
                            child: Slider(
                              value: controller.volume,
                              min: 0.0,
                              max: 1.0,
                              onChanged: (v) => controller.setVolume(v),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.volume_up_rounded,
                        color: Color(0xFF8888A0), size: 20),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final min = d.inMinutes.toString().padLeft(2, '0');
    final sec = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$min:$sec';
  }
}
