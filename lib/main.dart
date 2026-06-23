import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'player/audio_player_controller.dart';
import 'player/cast_manager.dart';
import 'player/music_database.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/player_screen.dart';
import 'ui/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (Platform.isAndroid) {
    final storageStatus = await Permission.storage.status;
    if (storageStatus.isDenied || storageStatus.isPermanentlyDenied) {
      await Permission.storage.request();
    }
    
    final audioStatus = await Permission.audio.status;
    if (audioStatus.isDenied || audioStatus.isPermanentlyDenied) {
      await Permission.audio.request();
    }
  }
  
  runApp(const MusicPlayerApp());
}

class MusicPlayerApp extends StatelessWidget {
  const MusicPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AudioPlayerController()),
        ChangeNotifierProvider(create: (_) => MusicDatabase()),
        ChangeNotifierProvider(create: (_) => CastManager()),
      ],
      child: MaterialApp(
        title: 'Aura Music',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const HomeScreen(),
        routes: {
          '/player': (context) => const PlayerScreen(),
        },
      ),
    );
  }
}
