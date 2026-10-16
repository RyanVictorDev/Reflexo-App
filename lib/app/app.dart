import 'package:flutter/material.dart';
import 'package:reflexo/app/app_route_observer.dart';
import 'package:reflexo/app/app_theme.dart';
import 'package:reflexo/audio/audio_controller.dart';
import 'package:reflexo/data/player_repository.dart';
import 'package:reflexo/features/home/home_page.dart';

class ReflexoApp extends StatefulWidget {
  const ReflexoApp({super.key});

  @override
  State<ReflexoApp> createState() => _ReflexoAppState();
}

class _ReflexoAppState extends State<ReflexoApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bootAudio();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _bootAudio() async {
    final profile = await PlayerRepository.instance.load();
    final audio = AudioController.instance;
    audio.musicOn = profile.musicOn;
    audio.sfxOn = profile.sfxOn;
    await audio.init();
    await audio.startMusic();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final audio = AudioController.instance;
    switch (state) {
      case AppLifecycleState.resumed:
        if (audio.musicOn) {
          audio.startMusic();
        }
        return;
      case AppLifecycleState.inactive:
        return;
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        audio.pauseMusic();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reflexo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      navigatorObservers: [appRouteObserver],
      home: const HomePage(),
    );
  }
}
