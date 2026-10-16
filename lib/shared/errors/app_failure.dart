class AppFailure implements Exception {
  final String message;
  final String code;
  const AppFailure(this.message, {this.code = 'UNKNOWN'});
  @override
  String toString() => message;
}
