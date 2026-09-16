import 'dart:async';



class AsyncMutex {
  Future<void> _chain = Future.value();

  Future<T> protect<T>(Future<T> Function() criticalSection) {
    final completer = Completer<T>();
    
    _chain = _chain.then((_) async {
      try {
        final result = await criticalSection();
        completer.complete(result);
      } catch (e, st) {
        completer.completeError(e, st);
      }
    });
    
    return completer.future;
  }
}
