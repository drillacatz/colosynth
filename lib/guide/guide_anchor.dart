import 'package:flutter/material.dart';


/// Global registry that maps string IDs to [GlobalKey]s for guide-targetable
/// UI elements.
///
/// Screens wrap their interactive widgets with [GuideAnchor] which auto-registers
/// the widget's key here. The [SpotlightMask] and [CoachBubble] then look up
/// widget positions via this registry to draw highlights and tooltips.
///
/// **Lifecycle safety**: Unlike the old `TutorialKeyRegistry` which only added
/// keys and never removed them (causing stale lookups after widget disposal),
/// this registry supports explicit deregistration via [unregister].
class GuideAnchorRegistry {
  GuideAnchorRegistry._();

  static final Map<String, GlobalKey> _keys = {};

  /// Returns the [GlobalKey] registered for [id], or `null` if not registered.
  static GlobalKey? getKey(String id) => _keys[id];

  /// Registers a [GlobalKey] for the given [id].
  /// If a key already exists for this ID, it is silently replaced.
  static void register(String id, GlobalKey key) {
    _keys[id] = key;
  }

  /// Removes the registration for [id].
  /// Safe to call even if [id] was never registered.
  static void unregister(String id) {
    _keys.remove(id);
  }

  /// Returns the on-screen bounding rectangle of the widget registered
  /// under [id], or `null` if the widget is not found / not yet laid out.
  static Rect? getRect(String id) {
    final key = _keys[id];
    if (key == null) return null;
    final context = key.currentContext;
    if (context == null) return null;
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return null;
    final offset = renderBox.localToGlobal(Offset.zero);
    return offset & renderBox.size;
  }

  /// Returns true if the widget for [id] is currently mounted and laid out.
  static bool isVisible(String id) => getRect(id) != null;

  /// Clears all registrations. Only used in tests or full app reset.
  @visibleForTesting
  static void clearAll() => _keys.clear();
}


/// A transparent wrapper that registers its child's [GlobalKey] in the
/// [GuideAnchorRegistry] so the guide system can locate and highlight it.
///
/// Usage:
/// ```dart
/// GuideAnchor(
///   id: 'arena_start_button',
///   child: ComicButton(label: 'START', ...),
/// )
/// ```
///
/// The widget automatically unregisters when disposed, preventing stale
/// key lookups that plagued the old `TutorialKeyRegistry`.
class GuideAnchor extends StatefulWidget {
  /// The unique identifier for this anchor. Must match the [anchorId]
  /// field in a [GuideStep] for the guide system to target this widget.
  final String id;

  /// The child widget to make guide-targetable.
  final Widget child;

  const GuideAnchor({
    super.key,
    required this.id,
    required this.child,
  });

  @override
  State<GuideAnchor> createState() => _GuideAnchorState();
}

class _GuideAnchorState extends State<GuideAnchor> {
  late final GlobalKey _anchorKey;

  @override
  void initState() {
    super.initState();
    _anchorKey = GlobalKey(debugLabel: 'GuideAnchor:${widget.id}');
    GuideAnchorRegistry.register(widget.id, _anchorKey);
  }

  @override
  void didUpdateWidget(GuideAnchor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) {
      GuideAnchorRegistry.unregister(oldWidget.id);
      GuideAnchorRegistry.register(widget.id, _anchorKey);
    }
  }

  @override
  void dispose() {
    GuideAnchorRegistry.unregister(widget.id);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: _anchorKey,
      child: widget.child,
    );
  }
}
