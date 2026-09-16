import 'package:flame/components.dart';

/// Lifecycle interface for components that need clean state reset upon recycling.
abstract mixin class Recyclable {
  void reset();
}

/// Generic, high-performance zero-allocation object pool for Flame [Component] instances.
/// Utilizes a LIFO stack ([List]) to guarantee O(1) acquisition and recycling.
class ComponentPool<T extends Component> {
  final T Function() _create;
  final List<T> _pool = [];
  final int maxCapacity;

  ComponentPool({
    required T Function() create,
    int initialSize = 8,
    this.maxCapacity = 64,
  }) : _create = create {
    for (var i = 0; i < initialSize; i++) {
      _pool.add(_create());
    }
  }

  /// Obtain an instance from the pool (or create a new one if pool is empty).
  /// Optional [initialize] callback configures the object before use.
  T obtain([void Function(T)? initialize]) {
    final T component;
    if (_pool.isNotEmpty) {
      component = _pool.removeLast();
    } else {
      component = _create();
    }
    initialize?.call(component);
    return component;
  }

  /// Recycle a component back into the pool for re-use.
  /// Safely detaches from Flame parent and triggers [Recyclable.reset] if implemented.
  void recycle(T component) {
    if (component.isMounted || component.parent != null) {
      component.removeFromParent();
    }
    if (component is Recyclable) {
      (component as Recyclable).reset();
    }
    if (_pool.length < maxCapacity) {
      _pool.add(component);
    }
  }

  /// Alias for [recycle] for API compatibility.
  void release(T component) => recycle(component);

  /// Clear all pooled instances.
  void clear() {
    _pool.clear();
  }

  /// Current number of idle pooled instances.
  int get pooledCount => _pool.length;
}

