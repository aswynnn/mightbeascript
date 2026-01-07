import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../app_state.dart';
import '../models.dart';

class StoryboardPanel extends StatelessWidget {
  const StoryboardPanel({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 40),
        ],
        border: Border(left: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Storyboard',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x),
                  onPressed: state.toggleStoryboard,
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: const DrawingCanvas(),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _ToolBtn(
                        icon: LucideIcons.pencil,
                        label: 'Pen',
                        isActive: !state.isEraser,
                        onTap: () => state.setTool(
                          state.currentColor,
                          state.currentWidth,
                          false,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ToolBtn(
                        icon: LucideIcons.eraser,
                        label: 'Eraser',
                        isActive: state.isEraser,
                        onTap: () => state.setTool(
                          state.currentColor,
                          state.currentWidth,
                          true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [Colors.black, Colors.red, Colors.blue]
                      .map(
                        (c) => GestureDetector(
                          onTap: () =>
                              state.setTool(c, state.currentWidth, false),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: state.clearCanvas,
                        child: const Text('Clear'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _ToolBtn({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: isActive ? Colors.blue : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? Colors.white : Colors.grey[700],
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DrawingCanvas extends StatefulWidget {
  const DrawingCanvas({super.key});
  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  DrawingStroke? _curr;
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Listener(
      onPointerDown: (d) => setState(
        () => _curr = DrawingStroke(
          [d.localPosition],
          s.currentColor,
          s.currentWidth,
          s.isEraser,
        ),
      ),
      onPointerMove: (d) => _curr != null
          ? setState(() => _curr!.points.add(d.localPosition))
          : null,
      onPointerUp: (d) {
        if (_curr != null) {
          s.addStroke(_curr!);
          setState(() => _curr = null);
        }
      },
      child: CustomPaint(
        painter: BoardPainter(s.strokes, _curr),
        size: Size.infinite,
      ),
    );
  }
}

class BoardPainter extends CustomPainter {
  final List<DrawingStroke> s;
  final DrawingStroke? c;
  BoardPainter(this.s, this.c);
  @override
  void paint(Canvas cv, Size sz) {
    cv.saveLayer(Rect.fromLTWH(0, 0, sz.width, sz.height), Paint());
    for (final k in [...s, if (c != null) c!]) {
      final p = Paint()
        ..color = k.isEraser ? Colors.transparent : k.color
        ..strokeWidth = k.width
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..blendMode = k.isEraser ? BlendMode.clear : BlendMode.srcOver;
      if (k.points.length > 1) {
        final path = Path()..moveTo(k.points[0].dx, k.points[0].dy);
        for (var i = 1; i < k.points.length; i++)
          path.lineTo(k.points[i].dx, k.points[i].dy);
        cv.drawPath(path, p);
      }
    }
    cv.restore();
  }

  @override
  bool shouldRepaint(covariant BoardPainter old) => true;
}
