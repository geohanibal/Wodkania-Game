/// Simple object pool for performance optimization
class ObjectPool<T> {
  ObjectPool(this._factory, {int initialSize = 10}) {
    for (var i = 0; i < initialSize; i++) {
      _available.add(_factory());
    }
  }

  final T Function() _factory;
  final List<T> _available = [];
  final List<T> _inUse = [];

  T obtain() {
    if (_available.isEmpty) {
      final obj = _factory();
      _inUse.add(obj);
      return obj;
    }

    final obj = _available.removeLast();
    _inUse.add(obj);
    return obj;
  }

  void free(T obj) {
    _inUse.remove(obj);
    _available.add(obj);
  }

  void freeAll() {
    _available.addAll(_inUse);
    _inUse.clear();
  }

  int get availableCount => _available.length;
  int get inUseCount => _inUse.length;
}
