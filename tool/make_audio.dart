import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

void main() {
  const rate = 22050;
  Directory('assets/audio').createSync(recursive: true);
  _write('assets/audio/music.wav', _music(rate, 8), rate);
  _write('assets/audio/collect.wav', _collect(rate), rate);
  _write('assets/audio/hit.wav', _hit(rate), rate);
  _write('assets/audio/switch.wav', _blip(rate, 740, 0.07), rate);
  _write('assets/audio/ui.wav', _blip(rate, 520, 0.05), rate);
}

List<double> _music(int rate, int seconds) {
  const notes = [220.0, 330.0, 247.0, 165.0, 220.0, 330.0, 196.0, 165.0];
  final count = rate * seconds;
  final samples = List<double>.filled(count, 0);
  for (var i = 0; i < count; i++) {
    final t = i / rate;
    final noteIndex = min(t.floor(), notes.length - 1);
    final local = t - noteIndex;
    final env = sin(pi * local.clamp(0.0, 1.0));
    final note = sin(2 * pi * notes[noteIndex] * t) * env * 0.22;
    final pad =
        sin(2 * pi * 110 * t) * 0.16 + sin(2 * pi * 165 * t) * 0.08;
    final beat = (t * 2) % 1;
    final pulse = exp(-beat * 8) * sin(2 * pi * 110 * t) * 0.12;
    samples[i] = note + pad + pulse;
  }
  return samples;
}

List<double> _collect(int rate) {
  const duration = 0.22;
  final count = (rate * duration).round();
  final samples = List<double>.filled(count, 0);
  for (var i = 0; i < count; i++) {
    final t = i / rate;
    final progress = t / duration;
    final freq = 620 + 540 * progress;
    final env = pow(1 - progress, 2).toDouble();
    samples[i] = sin(2 * pi * freq * t) * 0.45 * env;
  }
  return samples;
}

List<double> _hit(int rate) {
  const duration = 0.32;
  final count = (rate * duration).round();
  final random = Random(7);
  final samples = List<double>.filled(count, 0);
  for (var i = 0; i < count; i++) {
    final t = i / rate;
    final progress = t / duration;
    final env = pow(1 - progress, 3).toDouble();
    final noise = (random.nextDouble() * 2 - 1) * 0.35;
    final thud = sin(2 * pi * 96 * t) * 0.7;
    samples[i] = (thud + noise) * 0.5 * env;
  }
  return samples;
}

List<double> _blip(int rate, double freq, double duration) {
  final count = (rate * duration).round();
  final samples = List<double>.filled(count, 0);
  for (var i = 0; i < count; i++) {
    final t = i / rate;
    final progress = t / duration;
    final env = pow(1 - progress, 2).toDouble();
    samples[i] = sin(2 * pi * freq * t) * 0.35 * env;
  }
  return samples;
}

void _write(String path, List<double> samples, int rate) {
  final pcm = BytesBuilder();
  for (final sample in samples) {
    final value = (sample.clamp(-1.0, 1.0) * 32767).round();
    pcm.addByte(value & 0xff);
    pcm.addByte((value >> 8) & 0xff);
  }
  final body = pcm.toBytes();
  final header = BytesBuilder();
  void addString(String value) => header.add(value.codeUnits);
  void add32(int value) {
    header.addByte(value & 0xff);
    header.addByte((value >> 8) & 0xff);
    header.addByte((value >> 16) & 0xff);
    header.addByte((value >> 24) & 0xff);
  }

  void add16(int value) {
    header.addByte(value & 0xff);
    header.addByte((value >> 8) & 0xff);
  }

  addString('RIFF');
  add32(36 + body.length);
  addString('WAVE');
  addString('fmt ');
  add32(16);
  add16(1);
  add16(1);
  add32(rate);
  add32(rate * 2);
  add16(2);
  add16(16);
  addString('data');
  add32(body.length);
  File(path).writeAsBytesSync([...header.toBytes(), ...body]);
}
