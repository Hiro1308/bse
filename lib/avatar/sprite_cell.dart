import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SpriteCell extends StatefulWidget {
  final String assetPath;

  /// Tamaño REAL de un sprite completo (para tu caso: 32x64)
  final int cellWidthPx;
  final int cellHeightPx;

  /// Celda a mostrar (0-based)
  final int col;
  final int row;

  /// Tamaño del cuadro del preview
  final double size;

  /// Inset anti-bleed (1–2 px)
  final double insetPx;

  final bool debug;

  const SpriteCell({
    super.key,
    required this.assetPath,
    required this.col,
    required this.row,
    required this.size,
    this.cellWidthPx = 32,
    this.cellHeightPx = 64,
    this.insetPx = 1,
    this.debug = false,
  });

  @override
  State<SpriteCell> createState() => _SpriteCellState();
}

class _SpriteCellState extends State<SpriteCell> {
  ui.Image? _img;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant SpriteCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetPath != widget.assetPath) _load();
  }

  Future<void> _load() async {
    final bd = await rootBundle.load(widget.assetPath);
    final bytes = bd.buffer.asUint8List();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    if (!mounted) return;
    setState(() => _img = frame.image);
  }

  @override
  Widget build(BuildContext context) {
    final img = _img;
    if (img == null) return SizedBox(width: widget.size, height: widget.size);

    final cols = img.width ~/ widget.cellWidthPx;
    final rows = img.height ~/ widget.cellHeightPx;

    if (widget.debug && kDebugMode) {
      debugPrint(
        "SpriteCell img=${img.width}x${img.height} "
        "cell=${widget.cellWidthPx}x${widget.cellHeightPx} "
        "grid=${cols}x${rows} pick=(${widget.col},${widget.row})",
      );
    }

    return CustomPaint(
      size: Size(widget.size, widget.size),
      painter: _SpriteCellPainter(
        img: img,
        cellW: widget.cellWidthPx.toDouble(),
        cellH: widget.cellHeightPx.toDouble(),
        col: widget.col,
        row: widget.row,
        insetPx: widget.insetPx,
      ),
    );
  }
}

class _SpriteCellPainter extends CustomPainter {
  final ui.Image img;
  final double cellW;
  final double cellH;
  final int col;
  final int row;
  final double insetPx;

  _SpriteCellPainter({
    required this.img,
    required this.cellW,
    required this.cellH,
    required this.col,
    required this.row,
    required this.insetPx,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..isAntiAlias = false
      ..filterQuality = FilterQuality.none;

    final cols = (img.width / cellW).floor();
    final rows = (img.height / cellH).floor();

    final c = col.clamp(0, cols - 1);
    final r = row.clamp(0, rows - 1);

    final safeInset = insetPx.clamp(0.0, (cellW / 2) - 0.5);

    // SRC: 1 sprite completo (32x64)
    final src = Rect.fromLTWH(
      c * cellW + safeInset,
      r * cellH + safeInset,
      cellW - safeInset * 2,
      cellH - safeInset * 2,
    );

    // DST: contain centrado (sin zoom, sin recorte, sin deformar)
    final spriteAspect = cellW / cellH; // 0.5
    final boxW = size.width;
    final boxH = size.height;

    final fitWByH = boxH * spriteAspect;
    final dstW = (fitWByH <= boxW) ? fitWByH : boxW;
    final dstH = dstW / spriteAspect;

    final dx = (boxW - dstW) / 2;
    final dy = (boxH - dstH) / 2;

    final dst = Rect.fromLTWH(dx, dy, dstW, dstH);

    canvas.drawImageRect(img, src, dst, paint);
  }

  @override
  bool shouldRepaint(covariant _SpriteCellPainter old) {
    return old.img != img ||
        old.cellW != cellW ||
        old.cellH != cellH ||
        old.col != col ||
        old.row != row ||
        old.insetPx != insetPx;
  }
}
