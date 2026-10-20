class Lane {
  const Lane(this.index);

  final int index;

  static const left = Lane(0);
  static const right = Lane(1);

  /// Só vale na pista de duas faixas. Nas outras, o corredor seguro é explícito.
  Lane get opposite => index == 0 ? right : left;

  @override
  bool operator ==(Object other) => other is Lane && other.index == index;

  @override
  int get hashCode => index;

  @override
  String toString() => 'Lane($index)';
}
