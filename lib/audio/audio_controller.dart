import 'package:audioplayers/audioplayers.dart';

class AudioController {
  AudioController._();

  static final instance = AudioController._();

  /// A música segura o foco. Os efeitos misturam sem pedir foco, senão o
  /// Android pausa a música no primeiro som.
  static final _musicContext = AudioContext(
    android: AudioContextAndroid(
      contentType: AndroidContentType.music,
      usageType: AndroidUsageType.game,
      audioFocus: AndroidAudioFocus.gain,
    ),
  );

  static final _effectContext = AudioContext(
    android: AudioContextAndroid(
      contentType: AndroidContentType.sonification,
      usageType: AndroidUsageType.game,
      audioFocus: AndroidAudioFocus.none,
    ),
  );

  AudioPlayer? _music;
  final List<AudioPlayer> _effects = [];
  int _effectCursor = 0;
  bool musicOn = true;
  bool sfxOn = true;
  bool _ready = false;
  bool _musicStarted = false;

  Future<void> init() async {
    if (_ready) {
      return;
    }
    try {
      final music = AudioPlayer();
      await music.setAudioContext(_musicContext);
      await music.setReleaseMode(ReleaseMode.loop);
      await music.setVolume(0.9);
      _music = music;
      for (var i = 0; i < 4; i++) {
        final effect = AudioPlayer();
        await effect.setAudioContext(_effectContext);
        await effect.setReleaseMode(ReleaseMode.stop);
        await effect.setVolume(1);
        _effects.add(effect);
      }
      _ready = true;
    } catch (_) {
      _ready = false;
    }
  }

  Future<void> startMusic() async {
    if (!_ready || !musicOn || _music == null) {
      return;
    }
    try {
      if (!_musicStarted) {
        await _music!.play(AssetSource('audio/music.wav'));
        _musicStarted = true;
      }
      await _music!.resume();
    } catch (_) {}
  }

  Future<void> setMusic(bool enabled) async {
    musicOn = enabled;
    if (!_ready || _music == null) {
      return;
    }
    try {
      if (enabled) {
        await startMusic();
      } else {
        await _music!.pause();
      }
    } catch (_) {}
  }

  Future<void> setSfx(bool enabled) async {
    sfxOn = enabled;
  }

  Future<void> pauseMusic() async {
    if (!_ready || _music == null) {
      return;
    }
    try {
      await _music!.pause();
    } catch (_) {}
  }

  Future<void> playEffect(String name) async {
    if (!_ready || !sfxOn || _effects.isEmpty) {
      return;
    }
    final player = _effects[_effectCursor];
    _effectCursor = (_effectCursor + 1) % _effects.length;
    try {
      await player.play(AssetSource('audio/$name.wav'), ctx: _effectContext);
    } catch (_) {}
  }
}
