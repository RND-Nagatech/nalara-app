import 'dart:async';

/// Signals successful catalog writes so retained pages can reload canonical names.
class TeachingCatalogChanges {
  final _controller = StreamController<void>.broadcast();

  Stream<void> get stream => _controller.stream;

  void notifyChanged() {
    if (!_controller.isClosed) _controller.add(null);
  }

  Future<void> close() => _controller.close();
}
