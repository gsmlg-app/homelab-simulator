/// Exact base-10 arithmetic. Rounding belongs at the presentation boundary.
final class DecimalAmount implements Comparable<DecimalAmount> {
  final BigInt _coefficient;
  final int _scale;

  const DecimalAmount._(this._coefficient, this._scale);

  static final zero = DecimalAmount._(BigInt.zero, 0);

  factory DecimalAmount.parse(String value) {
    if (!RegExp(r'^-?\d+(\.\d+)?$').hasMatch(value)) {
      throw FormatException('Expected a finite decimal string', value);
    }
    final parts = value.split('.');
    final scale = parts.length == 1 ? 0 : parts[1].length;
    return DecimalAmount._(BigInt.parse(parts.join()), scale);
  }

  BigInt _atScale(int scale) =>
      _coefficient * BigInt.from(10).pow(scale - _scale);

  DecimalAmount operator +(DecimalAmount other) {
    final scale = _scale > other._scale ? _scale : other._scale;
    return DecimalAmount._(_atScale(scale) + other._atScale(scale), scale);
  }

  DecimalAmount operator -(DecimalAmount other) =>
      this + DecimalAmount._(-other._coefficient, other._scale);

  DecimalAmount operator *(DecimalAmount other) =>
      DecimalAmount._(_coefficient * other._coefficient, _scale + other._scale);

  bool get isZero => _coefficient == BigInt.zero;
  bool get isNegative => _coefficient.isNegative;

  @override
  int compareTo(DecimalAmount other) {
    final scale = _scale > other._scale ? _scale : other._scale;
    return _atScale(scale).compareTo(other._atScale(scale));
  }

  @override
  String toString() {
    if (isZero) return '0';
    var digits = _coefficient.abs().toString().padLeft(_scale + 1, '0');
    if (_scale > 0) {
      digits =
          '${digits.substring(0, digits.length - _scale)}.${digits.substring(digits.length - _scale)}';
      digits = digits
          .replaceFirst(RegExp(r'0+$'), '')
          .replaceFirst(RegExp(r'\.$'), '');
    }
    return '${isNegative ? '-' : ''}$digits';
  }

  @override
  bool operator ==(Object other) =>
      other is DecimalAmount && compareTo(other) == 0;

  @override
  int get hashCode => toString().hashCode;
}
