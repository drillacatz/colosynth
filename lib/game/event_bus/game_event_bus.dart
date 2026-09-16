import 'dart:async';
import 'package:colosynth/game/event_bus/game_events.dart';

class GameEventBus {
  GameEventBus._();
  static final GameEventBus instance = GameEventBus._();

  final _controller = StreamController<GameEvent>.broadcast();

  void emit(GameEvent event) {
    _controller.add(event);
  }

  Stream<T> on<T extends GameEvent>() {
    return _controller.stream.where((event) => event is T).cast<T>();
  }

}
