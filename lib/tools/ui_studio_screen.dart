import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import 'package:colosynth/widgets/common/app_comic_button.dart';

/// Supported visual element types in the UI Studio.
enum UiElementType {
  brushStroke,
  inkSplatter,
  comicText,
  comicButton,
  comicBadge,
}

/// Editable element model.
class UiStudioElement {
  UiStudioElement({
    required this.id,
    required this.type,
    required this.x,
    required this.y,
    this.width = 180,
    this.height = 60,
    this.scale = 1.0,
    this.rotationDeg = 0.0,
    this.opacity = 1.0,
    this.color = Colors.black,
    this.text = 'COMIC TEXT',
    this.fontSize = 22.0,
  });

  final String id;
  UiElementType type;
  double x;
  double y;
  double width;
  double height;
  double scale;
  double rotationDeg;
  double opacity;
  Color color;
  String text;
  double fontSize;

  Map<String, dynamic> toJson() {
    final hex = (color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase();
    return {
      'id': id,
      'type': type.name,
      'x': x.round(),
      'y': y.round(),
      'width': width.round(),
      'height': height.round(),
      'scale': double.parse(scale.toStringAsFixed(2)),
      'rotationDeg': rotationDeg.round(),
      'opacity': double.parse(opacity.toStringAsFixed(2)),
      'color': '#$hex',
      if (type == UiElementType.comicText ||
          type == UiElementType.comicButton ||
          type == UiElementType.comicBadge) ...{
        'text': text,
        'fontSize': fontSize.round(),
      },
    };
  }

  String toFlutterSnippet() {
    final rotRad = rotationDeg * (math.pi / 180.0);
    final hexColor = '0xFF${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

    switch (type) {
      case UiElementType.brushStroke:
        return '''
Positioned(
  left: ${x.round()},
  top: ${y.round()},
  child: Transform.rotate(
    angle: ${rotRad.toStringAsFixed(3)},
    child: Transform.scale(
      scale: ${scale.toStringAsFixed(2)},
      child: Opacity(
        opacity: ${opacity.toStringAsFixed(2)},
        child: Image.asset(
          'assets/images/brush_stroke.png',
          width: ${width.round()},
          height: ${height.round()},
          fit: BoxFit.fill,
          color: const Color($hexColor),
          colorBlendMode: BlendMode.srcIn,
        ),
      ),
    ),
  ),
),''';

      case UiElementType.inkSplatter:
        return '''
Positioned(
  left: ${x.round()},
  top: ${y.round()},
  child: Transform.rotate(
    angle: ${rotRad.toStringAsFixed(3)},
    child: Transform.scale(
      scale: ${scale.toStringAsFixed(2)},
      child: Opacity(
        opacity: ${opacity.toStringAsFixed(2)},
        child: Image.asset(
          'assets/images/ink_splatter.png',
          width: ${width.round()},
          height: ${height.round()},
          fit: BoxFit.contain,
          color: const Color($hexColor),
          colorBlendMode: BlendMode.srcIn,
        ),
      ),
    ),
  ),
),''';

      case UiElementType.comicText:
        return '''
Positioned(
  left: ${x.round()},
  top: ${y.round()},
  child: Transform.rotate(
    angle: ${rotRad.toStringAsFixed(3)},
    child: Transform.scale(
      scale: ${scale.toStringAsFixed(2)},
      child: Opacity(
        opacity: ${opacity.toStringAsFixed(2)},
        child: Text(
          '$text',
          style: TextStyle(
            fontFamily: 'Bangers',
            fontSize: ${fontSize.round()},
            color: const Color($hexColor),
            letterSpacing: 2.0,
          ),
        ),
      ),
    ),
  ),
),''';

      case UiElementType.comicButton:
        return '''
Positioned(
  left: ${x.round()},
  top: ${y.round()},
  child: Transform.rotate(
    angle: ${rotRad.toStringAsFixed(3)},
    child: Transform.scale(
      scale: ${scale.toStringAsFixed(2)},
      child: Opacity(
        opacity: ${opacity.toStringAsFixed(2)},
        child: AppComicButton(
          label: '$text',
          width: ${width.round()},
          height: ${height.round()},
          onTap: () {},
        ),
      ),
    ),
  ),
),''';

      case UiElementType.comicBadge:
        return '''
Positioned(
  left: ${x.round()},
  top: ${y.round()},
  child: Transform.rotate(
    angle: ${rotRad.toStringAsFixed(3)},
    child: Transform.scale(
      scale: ${scale.toStringAsFixed(2)},
      child: Opacity(
        opacity: ${opacity.toStringAsFixed(2)},
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color($hexColor),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.black, width: 2.5),
            boxShadow: const [
              BoxShadow(color: Colors.black, offset: Offset(3, 3)),
            ],
          ),
          child: Text(
            '$text',
            style: TextStyle(
              fontFamily: 'Bangers',
              fontSize: ${fontSize.round()},
              color: Colors.white,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    ),
  ),
),''';
    }
  }
}

/// Floating Draggable Debug Bubble to toggle UI Studio.
class UiStudioBubble extends StatefulWidget {
  const UiStudioBubble({super.key, required this.child});
  final Widget child;

  @override
  State<UiStudioBubble> createState() => _UiStudioBubbleState();
}

class _UiStudioBubbleState extends State<UiStudioBubble> {
  Offset _pos = const Offset(16, 120);

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return widget.child;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          widget.child,
          Positioned(
            left: _pos.dx,
            top: _pos.dy,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  final size = MediaQuery.of(context).size;
                  final newX = (_pos.dx + details.delta.dx)
                      .clamp(8.0, size.width - 56.0);
                  final newY = (_pos.dy + details.delta.dy)
                      .clamp(32.0, size.height - 56.0);
                  _pos = Offset(newX, newY);
                });
              },
              onTap: () {
                Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(builder: (_) => const UiStudioScreen()),
                );
              },
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD600),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 2.5),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black,
                        offset: Offset(2.5, 2.5),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.brush,
                      color: Colors.black,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Interactive in-app visual UI design studio.
class UiStudioScreen extends StatefulWidget {
  const UiStudioScreen({super.key});

  @override
  State<UiStudioScreen> createState() => _UiStudioScreenState();
}

class _UiStudioScreenState extends State<UiStudioScreen> {
  final List<UiStudioElement> _elements = [];
  String? _selectedId;
  Color _canvasBg = const Color(0xFF181818);
  bool _showGrid = true;
  int _counter = 0;

  UiStudioElement? get _selected {
    if (_selectedId == null) return null;
    try {
      return _elements.firstWhere((e) => e.id == _selectedId);
    } catch (_) {
      return null;
    }
  }

  void _addElement(UiElementType type) {
    final screenSize = MediaQuery.of(context).size;
    final centerX = (screenSize.width / 2) - 80;
    final centerY = (screenSize.height / 3) - 30;
    _counter++;

    final newEl = UiStudioElement(
      id: 'el_$_counter',
      type: type,
      x: centerX + (_counter * 10 % 50),
      y: centerY + (_counter * 10 % 50),
      width: type == UiElementType.inkSplatter ? 120 : 180,
      height: type == UiElementType.inkSplatter ? 120 : 54,
      color: type == UiElementType.comicText
          ? Colors.white
          : (type == UiElementType.comicButton
              ? const Color(0xFFFFD600)
              : Colors.black),
      text: type == UiElementType.comicButton
          ? 'ACTION'
          : (type == UiElementType.comicBadge ? 'BADGE' : 'COMIC TEXT'),
    );

    setState(() {
      _elements.add(newEl);
      _selectedId = newEl.id;
    });
  }

  Future<void> _exportParameters() async {
    final screenSize = MediaQuery.of(context).size;
    final exportData = {
      'timestamp': DateTime.now().toIso8601String(),
      'canvasWidth': screenSize.width.round(),
      'canvasHeight': screenSize.height.round(),
      'elements': _elements.map((e) => e.toJson()).toList(),
    };

    final jsonStr = const JsonEncoder.withIndent('  ').convert(exportData);
    final flutterSnippets = _elements.map((e) => e.toFlutterSnippet()).join('\n');

    final fullExport = '''
// ==================== COLOSYNTH UI EXPORT ====================
// JSON PARAMETERS:
$jsonStr

// FLUTTER CODE SNIPPET:
Stack(
  children: [
$flutterSnippets
  ],
)
// =============================================================
''';

    // 1. Copy to clipboard
    await Clipboard.setData(ClipboardData(text: fullExport));

    // 2. Save to local phone storage
    String savedFilePath = '';
    try {
      final downloadDir = Directory('/storage/emulated/0/Download');
      final targetDir = downloadDir.existsSync() ? downloadDir : Directory.systemTemp;
      final file = File('${targetDir.path}/colosynth_ui_export.json');
      await file.writeAsString(jsonStr);
      savedFilePath = file.path;
    } catch (_) {
      try {
        final tmpFile = File('${Directory.systemTemp.path}/colosynth_ui_export.json');
        await tmpFile.writeAsString(jsonStr);
        savedFilePath = tmpFile.path;
      } catch (_) {}
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF00E676),
        duration: const Duration(seconds: 3),
        content: Text(
          'Copied to clipboard! Saved to: $savedFilePath',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontFamily: 'Bangers',
            letterSpacing: 1.2,
          ),
        ),
        action: SnackBarAction(
          label: 'SHARE',
          textColor: Colors.black,
          onPressed: () {
            SharePlus.instance.share(
              ShareParams(text: fullExport, subject: 'ColoSynth UI Export'),
            );
          },
        ),
      ),
    );

    // Prompt native share sheet
    unawaited(
      SharePlus.instance.share(
        ShareParams(text: fullExport, subject: 'ColoSynth UI Export'),
      ),
    );
  }

  void _showTextEditorDialog(UiStudioElement el) {
    final ctrl = TextEditingController(text: el.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF222222),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.white24),
        ),
        title: const Text(
          'EDIT LABEL',
          style: TextStyle(
            fontFamily: 'Bangers',
            color: Colors.white,
            letterSpacing: 1.5,
          ),
        ),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Enter text...',
            hintStyle: TextStyle(color: Colors.white38),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFFFD600)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              setState(() => el.text = ctrl.text);
              Navigator.pop(ctx);
            },
            child: const Text('SAVE', style: TextStyle(color: Color(0xFFFFD600))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _canvasBg,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            _buildTopBar(),

            // Interactive Canvas
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => setState(() => _selectedId = null),
                child: Stack(
                  children: [
                    // Grid pattern overlay
                    if (_showGrid) _buildGridOverlay(),

                    // Elements
                    for (final el in _elements) _buildCanvasElement(el),
                  ],
                ),
              ),
            ),

            // Bottom Inspector / Toolbar
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        border: Border(bottom: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            tooltip: 'Close Studio',
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          const Text(
            'UI STUDIO',
            style: TextStyle(
              fontFamily: 'Bangers',
              fontSize: 20,
              color: Color(0xFFFFD600),
              letterSpacing: 2.0,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              _showGrid ? Icons.grid_on : Icons.grid_off,
              color: Colors.white70,
              size: 20,
            ),
            tooltip: 'Toggle Grid',
            onPressed: () => setState(() => _showGrid = !_showGrid),
          ),
          IconButton(
            icon: const Icon(Icons.palette_outlined, color: Colors.white70, size: 20),
            tooltip: 'Canvas Background',
            onPressed: () {
              setState(() {
                if (_canvasBg == const Color(0xFF181818)) {
                  _canvasBg = const Color(0xFFF5F5F0);
                } else if (_canvasBg == const Color(0xFFF5F5F0)) {
                  _canvasBg = const Color(0xFF0D0D0D);
                } else {
                  _canvasBg = const Color(0xFF181818);
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent, size: 22),
            tooltip: 'Clear All',
            onPressed: () {
              if (_elements.isEmpty) return;
              setState(() {
                _elements.clear();
                _selectedId = null;
              });
            },
          ),
          const SizedBox(width: 4),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD600),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Colors.black, width: 2),
              ),
            ),
            icon: const Icon(Icons.file_upload_outlined, size: 18),
            label: const Text(
              'EXPORT',
              style: TextStyle(
                fontFamily: 'Bangers',
                fontSize: 16,
                letterSpacing: 1.5,
              ),
            ),
            onPressed: _elements.isEmpty ? null : _exportParameters,
          ),
        ],
      ),
    );
  }

  Widget _buildGridOverlay() {
    return CustomPaint(
      size: Size.infinite,
      painter: _GridPainter(
        lineColor: _canvasBg == const Color(0xFFF5F5F0)
            ? Colors.black12
            : Colors.white12,
      ),
    );
  }

  Widget _buildCanvasElement(UiStudioElement el) {
    final isSelected = el.id == _selectedId;
    final rotRad = el.rotationDeg * (math.pi / 180.0);

    return Positioned(
      left: el.x,
      top: el.y,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _selectedId = el.id),
        onPanUpdate: (details) {
          setState(() {
            _selectedId = el.id;
            el.x += details.delta.dx;
            el.y += details.delta.dy;
          });
        },
        child: Transform.rotate(
          angle: rotRad,
          child: Transform.scale(
            scale: el.scale,
            child: Opacity(
              opacity: el.opacity.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  border: isSelected
                      ? Border.all(color: const Color(0xFF00E5FF), width: 2.0)
                      : null,
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _renderElementContent(el),
                    if (isSelected)
                      Positioned(
                        right: -10,
                        top: -10,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _elements.removeWhere((e) => e.id == el.id);
                              _selectedId = null;
                            });
                          },
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _renderElementContent(UiStudioElement el) {
    switch (el.type) {
      case UiElementType.brushStroke:
        return Image.asset(
          'assets/images/brush_stroke.png',
          width: el.width,
          height: el.height,
          fit: BoxFit.fill,
          color: el.color,
          colorBlendMode: BlendMode.srcIn,
        );

      case UiElementType.inkSplatter:
        return Image.asset(
          'assets/images/ink_splatter.png',
          width: el.width,
          height: el.height,
          fit: BoxFit.contain,
          color: el.color,
          colorBlendMode: BlendMode.srcIn,
        );

      case UiElementType.comicText:
        return Text(
          el.text,
          style: TextStyle(
            fontFamily: 'Bangers',
            fontSize: el.fontSize,
            color: el.color,
            letterSpacing: 2.0,
            shadows: const [
              Shadow(
                color: Colors.black87,
                offset: Offset(2, 2),
                blurRadius: 1,
              ),
            ],
          ),
        );

      case UiElementType.comicButton:
        return SizedBox(
          width: el.width,
          height: el.height,
          child: AppComicButton(
            label: el.text,
            fontSize: el.fontSize,
            onTap: () {},
          ),
        );

      case UiElementType.comicBadge:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: el.color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.black, width: 2.5),
            boxShadow: const [
              BoxShadow(color: Colors.black, offset: Offset(3, 3)),
            ],
          ),
          child: Text(
            el.text,
            style: TextStyle(
              fontFamily: 'Bangers',
              fontSize: el.fontSize,
              color: Colors.white,
              letterSpacing: 1.5,
            ),
          ),
        );
    }
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Inspector if selected, otherwise quick-add bar
          if (_selected != null) ...[
            _buildInspector(_selected!),
          ] else ...[
            _buildQuickAddBar(),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickAddBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _addBtn('+ BRUSH STROKE', () => _addElement(UiElementType.brushStroke)),
          const SizedBox(width: 8),
          _addBtn('+ INK SPLATTER', () => _addElement(UiElementType.inkSplatter)),
          const SizedBox(width: 8),
          _addBtn('+ COMIC TEXT', () => _addElement(UiElementType.comicText)),
          const SizedBox(width: 8),
          _addBtn('+ BUTTON', () => _addElement(UiElementType.comicButton)),
          const SizedBox(width: 8),
          _addBtn('+ BADGE', () => _addElement(UiElementType.comicBadge)),
        ],
      ),
    );
  }

  Widget _addBtn(String label, VoidCallback onPressed) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFFFD600),
        side: const BorderSide(color: Color(0xFFFFD600)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      onPressed: onPressed,
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Bangers',
          fontSize: 14,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildInspector(UiStudioElement el) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header & Quick Actions
        Row(
          children: [
            Text(
              el.type.name.toUpperCase(),
              style: const TextStyle(
                fontFamily: 'Bangers',
                fontSize: 16,
                color: Color(0xFF00E5FF),
                letterSpacing: 1.5,
              ),
            ),
            const Spacer(),
            if (el.type == UiElementType.comicText ||
                el.type == UiElementType.comicButton ||
                el.type == UiElementType.comicBadge)
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white70, size: 18),
                tooltip: 'Edit text',
                onPressed: () => _showTextEditorDialog(el),
              ),
            IconButton(
              icon: const Icon(Icons.flip_to_front, color: Colors.white70, size: 18),
              tooltip: 'Bring to Front',
              onPressed: () {
                setState(() {
                  _elements.remove(el);
                  _elements.add(el);
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.flip_to_back, color: Colors.white70, size: 18),
              tooltip: 'Send to Back',
              onPressed: () {
                setState(() {
                  _elements.remove(el);
                  _elements.insert(0, el);
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18),
              tooltip: 'Delete',
              onPressed: () {
                setState(() {
                  _elements.removeWhere((e) => e.id == el.id);
                  _selectedId = null;
                });
              },
            ),
          ],
        ),

        // Sliders: Scale & Rotation
        Row(
          children: [
            const Text('SCALE', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
            Expanded(
              child: Slider(
                value: el.scale,
                min: 0.3,
                max: 3.5,
                divisions: 32,
                activeColor: const Color(0xFFFFD600),
                onChanged: (v) => setState(() => el.scale = v),
              ),
            ),
            Text(el.scale.toStringAsFixed(1), style: const TextStyle(color: Colors.white70, fontSize: 10)),
            const SizedBox(width: 8),
            const Text('ROT', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
            Expanded(
              child: Slider(
                value: el.rotationDeg,
                min: -180.0,
                max: 180.0,
                divisions: 36,
                activeColor: const Color(0xFFFFD600),
                onChanged: (v) => setState(() => el.rotationDeg = v),
              ),
            ),
            Text('${el.rotationDeg.round()} deg', style: const TextStyle(color: Colors.white70, fontSize: 10)),
          ],
        ),

        // Sliders: Width/Height or Opacity
        Row(
          children: [
            const Text('OPACITY', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
            Expanded(
              child: Slider(
                value: el.opacity,
                min: 0.1,
                max: 1.0,
                divisions: 18,
                activeColor: const Color(0xFFFFD600),
                onChanged: (v) => setState(() => el.opacity = v),
              ),
            ),
            Text(el.opacity.toStringAsFixed(1), style: const TextStyle(color: Colors.white70, fontSize: 10)),
            const SizedBox(width: 8),
            // Color Presets
            _colorDot(el, Colors.black),
            _colorDot(el, Colors.white),
            _colorDot(el, const Color(0xFFFFD600)),
            _colorDot(el, const Color(0xFFE53935)),
            _colorDot(el, const Color(0xFF00E5FF)),
          ],
        ),
      ],
    );
  }

  Widget _colorDot(UiStudioElement el, Color c) {
    final isCurrent = el.color.toARGB32() == c.toARGB32();
    return GestureDetector(
      onTap: () => setState(() => el.color = c),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: c,
          shape: BoxShape.circle,
          border: Border.all(
            color: isCurrent ? const Color(0xFF00E5FF) : Colors.white54,
            width: isCurrent ? 2 : 1,
          ),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter({required this.lineColor});
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.0;

    const step = 32.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => oldDelegate.lineColor != lineColor;
}
