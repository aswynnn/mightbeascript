import 'dart:ui';

class SceneHeading {
  final String text;
  final int position;
  final String type; // 'INT' or 'EXT'
  final int index;

  SceneHeading({
    required this.text,
    required this.position,
    required this.type,
    required this.index,
  });
}

class DrawingStroke {
  final List<Offset> points;
  final Color color;
  final double width;
  final bool isEraser;

  DrawingStroke(this.points, this.color, this.width, this.isEraser);
}
