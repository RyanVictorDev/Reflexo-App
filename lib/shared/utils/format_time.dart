String formatPlayTime(double seconds) {
  final total = seconds.floor().clamp(0, 359999);
  final minutes = (total ~/ 60).toString().padLeft(2, '0');
  final secs = (total % 60).toString().padLeft(2, '0');
  return '$minutes:$secs';
}
