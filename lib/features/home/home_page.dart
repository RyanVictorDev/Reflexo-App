import 'dart:async';

import 'package:flutter/material.dart';
import 'package:reflexo/audio/audio_controller.dart';
import 'package:reflexo/data/player_repository.dart';
import 'package:reflexo/domain/player_profile.dart';
import 'package:reflexo/features/colors/colors_page.dart';
import 'package:reflexo/features/gameplay/gameplay_page.dart';
import 'package:reflexo/shared/widgets/centered_menu.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  PlayerProfile _profile = PlayerProfile.initial();

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final profile = await PlayerRepository.instance.load();
    if (!mounted) {
      return;
    }
    setState(() => _profile = profile);
    AudioController.instance
      ..musicOn = profile.musicOn
      ..sfxOn = profile.sfxOn;
  }

  Future<void> _open(Widget page) async {
    unawaited(AudioController.instance.playEffect('ui'));
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => page));
    await _reload();
  }

  Future<void> _toggleMusic() async {
    final next = _profile.copyWith(musicOn: !_profile.musicOn);
    setState(() => _profile = next);
    await PlayerRepository.instance.save(next);
    await AudioController.instance.setMusic(next.musicOn);
  }

  Future<void> _toggleSfx() async {
    final next = _profile.copyWith(sfxOn: !_profile.sfxOn);
    setState(() => _profile = next);
    await PlayerRepository.instance.save(next);
    await AudioController.instance.setSfx(next.sfxOn);
    if (next.sfxOn) {
      unawaited(AudioController.instance.playEffect('ui'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final style = _profile.style;
    return Scaffold(
      body: CenteredMenu(
        children: [
          _LogoMark(core: style.core, mid: style.mid, glow: style.glow),
          const SizedBox(height: 24),
          Text(
            'Reflexo',
            textAlign: TextAlign.center,
            style: text.displaySmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Desvie. Colete. Sobreviva.',
            textAlign: TextAlign.center,
            style: text.titleMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 20),
          Text(
            'Recorde ${_profile.bestScore}',
            textAlign: TextAlign.center,
            style: text.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Moedas ${_profile.coins}',
            textAlign: TextAlign.center,
            style: text.titleMedium,
          ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: () => _open(const GameplayPage()),
            child: const Text('Jogar'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => _open(const ColorsPage()),
            child: const Text('Cores da bola'),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: _profile.musicOn ? 'Desligar música' : 'Ligar música',
                onPressed: _toggleMusic,
                icon: Icon(
                  _profile.musicOn ? Icons.music_note : Icons.music_off,
                ),
              ),
              IconButton(
                tooltip: _profile.sfxOn ? 'Desligar efeitos' : 'Ligar efeitos',
                onPressed: _toggleSfx,
                icon: Icon(_profile.sfxOn ? Icons.volume_up : Icons.volume_off),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LogoMark extends StatefulWidget {
  const _LogoMark({required this.core, required this.mid, required this.glow});

  final Color core;
  final Color mid;
  final Color glow;

  @override
  State<_LogoMark> createState() => _LogoMarkState();
}

class _LogoMarkState extends State<_LogoMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(
        begin: 0.94,
        end: 1.06,
      ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut)),
      child: SizedBox(
        width: 112,
        height: 112,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.glow,
            border: Border.all(color: widget.mid, width: 3),
          ),
          child: Center(
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.core,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
