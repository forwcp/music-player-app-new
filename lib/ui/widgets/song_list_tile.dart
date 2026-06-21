import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:music_player_app/player/audio_player_controller.dart';

class SongListTile extends StatelessWidget {
  final int index;
  final String title;
  final String artist;
  final VoidCallback onTap;

  const SongListTile({
    super.key,
    required this.index,
    required this.title,
    required this.artist,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AudioPlayerController>();
    final isCurrentTrack = controller.currentIndex == index;

    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: isCurrentTrack
              ? const LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                )
              : null,
          color: isCurrentTrack ? null : const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: isCurrentTrack
              ? Icon(Icons.music_note_rounded, color: Colors.white, size: 24)
              : Icon(Icons.notes_rounded, color: Colors.white.withValues(alpha:0.4), size: 24),
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isCurrentTrack ? const Color(0xFF667eea) : Colors.white,
          fontWeight: isCurrentTrack ? FontWeight.w600 : FontWeight.normal,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        artist,
        style: const TextStyle(color: Color(0xFF8888A0)),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: isCurrentTrack && controller.isPlaying
          ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(const Color(0xFF667eea)),
              ),
            )
          : null,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }
}
