import 'package:bse/avatar/sprite_cell.dart';
import 'package:flutter/material.dart';
import 'avatar_model.dart';

class AvatarPreview extends StatelessWidget {
  final AvatarConfig cfg;
  final double size;

  const AvatarPreview({super.key, required this.cfg, required this.size});

  @override
  Widget build(BuildContext context) {
    const cols = 4;
    const rows = 4;
    const col = 0;              // izquierda
    final row = cfg.facingRow;  // 0..3


    Widget layer(String? p) {
      if (p == null || p.isEmpty) return const SizedBox.shrink();
      return SpriteCell(
        assetPath: p,
        col: 0,
        row: cfg.facingRow, // default 2
        size: 200,
        cellWidthPx: 64,
        cellHeightPx: 64,
        insetPx: 1,
      ); 
    }

    // Importante: NO uses Transform.scale afuera sin clip.
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          layer(cfg.bodyBase),
          layer(cfg.head),
          layer(cfg.eyes),
          layer(cfg.hair),
          layer(cfg.clothes),
          layer(cfg.accessory),
          ...cfg.bodyAddons.map(layer),
        ],
      ),
    );
  }
}
