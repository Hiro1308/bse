import 'package:flutter/material.dart';
import 'avatar_assets.dart';
import 'avatar_capture.dart';
import 'avatar_model.dart';
import 'avatar_preview.dart';
import 'avatar_storage.dart';

enum AvatarCategory { body, addons, hair, eyes, clothes, accessory }

extension _AvatarCategoryX on AvatarCategory {
  String get label {
    switch (this) {
      case AvatarCategory.body:
        return 'Body';
      case AvatarCategory.addons:
        return 'Add-ons';
      case AvatarCategory.hair:
        return 'Hair';
      case AvatarCategory.eyes:
        return 'Eyes';
      case AvatarCategory.clothes:
        return 'Clothes';
      case AvatarCategory.accessory:
        return 'Accessory';
    }
  }
}

class AvatarEditorScreen extends StatefulWidget {
  final AvatarCatalog catalog;
  final AvatarConfig initial;

  const AvatarEditorScreen({super.key, required this.catalog, required this.initial});

  @override
  State<AvatarEditorScreen> createState() => _AvatarEditorScreenState();
}

class _AvatarEditorScreenState extends State<AvatarEditorScreen> {
  late AvatarConfig cfg;
  final GlobalKey _repaintKey = GlobalKey();

  final skinOptions = const [
    Color(0xFFFFD7C2),
    Color(0xFFF2C6A0),
    Color(0xFFE3AC83),
    Color(0xFFC98C5B),
    Color(0xFF8D5A3A),
  ];

  @override
  void initState() {
    super.initState();
    cfg = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    final cat = widget.catalog;

    // Body list (según tu modelo actual)
    final isMale = cfg.bodyGender == "male";
    final bodyList = isMale ? cat.bodyMaleBases : cat.bodyFemaleBases;
    final bodyIdle = isMale ? (cat.bodyMaleIdle ?? "") : (cat.bodyFemaleIdle ?? "");

    return Scaffold(
      appBar: AppBar(title: const Text('Creador de personaje')),
      body: Column(
        children: [
          const SizedBox(height: 12),

          Center(
            child: RepaintBoundary(
              key: _repaintKey,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.white12),
                ),
                child: AvatarPreview(cfg: cfg, size: 200),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // === FILAS TIPO STARDEW ===
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              children: [
                // Row 1: Head + Hair
                _RowDoubleCycle(
                  left: _MiniCycle(
                    label: 'Head',
                    value: cfg.head == null ? 'None' : _nicePath(cfg.head!),
                    countText: widget.catalog.heads.isEmpty
                        ? "0/0"
                        : "${_indexOfNullable([null, ...widget.catalog.heads], cfg.head) + 1}/${widget.catalog.heads.length + 1}",
                    onPrev: widget.catalog.heads.isEmpty
                        ? null
                        : () {
                            final list = <String?>[null, ...widget.catalog.heads];
                            final next = _cyclePrevNullable(list, cfg.head);
                            setState(() => cfg = cfg.copyWith(head: next));
                          },
                    onNext: widget.catalog.heads.isEmpty
                        ? null
                        : () {
                            final list = <String?>[null, ...widget.catalog.heads];
                            final next = _cycleNextNullable(list, cfg.head);
                            setState(() => cfg = cfg.copyWith(head: next));
                          },
                    onTap: () => _openStripPickerNullable(
                      title: 'Head',
                      items: [null, ...widget.catalog.heads],
                      selected: cfg.head,
                      onSelect: (p) => setState(() => cfg = cfg.copyWith(head: p)),
                    ),
                  ),
                  right: _MiniCycle(
                    label: 'Hair',
                    value: cfg.hair == null ? 'None' : _nicePath(cfg.hair!),
                    countText: cat.hairs.isEmpty
                        ? "0/0"
                        : "${_indexOfNullable([null, ...cat.hairs], cfg.hair) + 1}/${cat.hairs.length + 1}",
                    onPrev: cat.hairs.isEmpty
                        ? null
                        : () {
                            final list = <String?>[null, ...cat.hairs];
                            final next = _cyclePrevNullable(list, cfg.hair);
                            setState(() => cfg = cfg.copyWith(hair: next));
                          },
                    onNext: cat.hairs.isEmpty
                        ? null
                        : () {
                            final list = <String?>[null, ...cat.hairs];
                            final next = _cycleNextNullable(list, cfg.hair);
                            setState(() => cfg = cfg.copyWith(hair: next));
                          },
                    onTap: () => _openStripPickerNullable(
                      title: 'Hair',
                      items: [null, ...cat.hairs],
                      selected: cfg.hair,
                      onSelect: (p) => setState(() => cfg = cfg.copyWith(hair: p)),
                    ),
                  ),
                ),

                // Row 2: Body + Clothes
                _RowDoubleCycle(
                  left: _MiniCycle(
                    label: 'Body',
                    value: _nicePath(cfg.bodyBase),
                    countText: bodyList.isEmpty ? "0/0" : "${_indexOf(bodyList, cfg.bodyBase) + 1}/${bodyList.length}",
                    onPrev: bodyList.isEmpty
                        ? null
                        : () {
                            final next = _cyclePrev(bodyList, cfg.bodyBase);
                            setState(() => cfg = cfg.copyWith(bodyIdle: bodyIdle, bodyBase: next));
                          },
                    onNext: bodyList.isEmpty
                        ? null
                        : () {
                            final next = _cycleNext(bodyList, cfg.bodyBase);
                            setState(() => cfg = cfg.copyWith(bodyIdle: bodyIdle, bodyBase: next));
                          },
                    onTap: () => _openStripPicker(
                      title: 'Body',
                      items: bodyList,
                      selected: cfg.bodyBase,
                      onSelect: (p) => setState(() => cfg = cfg.copyWith(bodyIdle: bodyIdle, bodyBase: p)),
                    ),
                  ),
                  right: _MiniCycle(
                    label: 'Clothes',
                    value: cfg.clothes.isEmpty ? 'None' : _nicePath(cfg.clothes),
                    countText: cat.clothes.isEmpty ? "0/0" : "${_indexOf(cat.clothes, cfg.clothes) + 1}/${cat.clothes.length}",
                    onPrev: cat.clothes.isEmpty
                        ? null
                        : () {
                            final next = _cyclePrev(cat.clothes, cfg.clothes);
                            setState(() => cfg = cfg.copyWith(clothes: next));
                          },
                    onNext: cat.clothes.isEmpty
                        ? null
                        : () {
                            final next = _cycleNext(cat.clothes, cfg.clothes);
                            setState(() => cfg = cfg.copyWith(clothes: next));
                          },
                    onTap: () => _openStripPicker(
                      title: 'Clothes',
                      items: cat.clothes,
                      selected: cfg.clothes,
                      onSelect: (p) => setState(() => cfg = cfg.copyWith(clothes: p)),
                    ),
                  ),
                ),

                // Row 3: Add-ons + Accessory
                _RowDoubleCycle(
                  left: _MiniCycle(
                    label: 'Add-ons',
                    value: cfg.bodyAddons.isEmpty ? 'None' : '${cfg.bodyAddons.length} selected',
                    countText: '${cfg.bodyAddons.length}',
                    onPrev: null,
                    onNext: null,
                    onTap: () => _openAddonsPicker(),
                  ),
                  right: _MiniCycle(
                    label: 'Accessory',
                    value: cfg.accessory == null ? 'None' : _nicePath(cfg.accessory!),
                    countText: cat.accessories.isEmpty
                        ? "0/0"
                        : "${_indexOfNullable([null, ...cat.accessories], cfg.accessory) + 1}/${cat.accessories.length + 1}",
                    onPrev: cat.accessories.isEmpty
                        ? null
                        : () {
                            final list = <String?>[null, ...cat.accessories];
                            final next = _cyclePrevNullable(list, cfg.accessory);
                            setState(() => cfg = cfg.copyWith(accessory: next));
                          },
                    onNext: cat.accessories.isEmpty
                        ? null
                        : () {
                            final list = <String?>[null, ...cat.accessories];
                            final next = _cycleNextNullable(list, cfg.accessory);
                            setState(() => cfg = cfg.copyWith(accessory: next));
                          },
                    onTap: () => _openStripPickerNullable(
                      title: 'Accessory',
                      items: [null, ...cat.accessories],
                      selected: cfg.accessory,
                      onSelect: (p) => setState(() => cfg = cfg.copyWith(accessory: p)),
                    ),
                  ),
                ),

                // Row 4: Eyes + Rotate
                _RowDoubleCycle(
                  left: _MiniCycle(
                    label: 'Eyes',
                    value: cfg.eyes.isEmpty ? 'None' : _nicePath(cfg.eyes),
                    countText: cat.eyes.isEmpty ? "0/0" : "${_indexOf(cat.eyes, cfg.eyes) + 1}/${cat.eyes.length}",
                    onPrev: cat.eyes.isEmpty
                        ? null
                        : () {
                            final next = _cyclePrev(cat.eyes, cfg.eyes);
                            setState(() => cfg = cfg.copyWith(eyes: next));
                          },
                    onNext: cat.eyes.isEmpty
                        ? null
                        : () {
                            final next = _cycleNext(cat.eyes, cfg.eyes);
                            setState(() => cfg = cfg.copyWith(eyes: next));
                          },
                    onTap: () => _openStripPicker(
                      title: 'Eyes',
                      items: cat.eyes,
                      selected: cfg.eyes,
                      onSelect: (p) => setState(() => cfg = cfg.copyWith(eyes: p)),
                    ),
                  ),
                  right: _MiniCycle(
                    label: 'Rotate',
                    value: const ['Back', 'Right', 'Front', 'Left'][cfg.facingRow.clamp(0, 3)],
                    countText: '${(cfg.facingRow.clamp(0, 3)) + 1}/4',
                    onPrev: () => setState(() => cfg = cfg.copyWith(facingRow: (cfg.facingRow - 1 + 4) % 4)),
                    onNext: () => setState(() => cfg = cfg.copyWith(facingRow: (cfg.facingRow + 1) % 4)),
                    onTap: () {}, // sin modal
                  ),
                ),

                const SizedBox(height: 10),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: FilledButton.icon(
              onPressed: () async {
                final png = await capturePng(_repaintKey, pixelRatio: 4);
                await AvatarStorage.saveAvatarImageLocally(png);
                await AvatarStorage.saveConfig(cfg);

                if (!mounted) return;
                Navigator.pop(context, cfg);
              },
              icon: const Icon(Icons.save),
              label: const Text('Guardar como foto de perfil'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openStripPicker({
    required String title,
    required List<String> items,
    required String selected,
    required ValueChanged<String> onSelect,
  }) async {
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => _StripPicker(
        title: title,
        items: items,
        selected: selected,
        onSelect: (p) {
          Navigator.pop(context);
          onSelect(p);
        },
      ),
    );
  }

  Future<void> _openStripPickerNullable({
    required String title,
    required List<String?> items,
    required String? selected,
    required ValueChanged<String?> onSelect,
  }) async {
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => _StripPickerNullable(
        title: title,
        items: items,
        selected: selected,
        onSelect: (p) {
          Navigator.pop(context);
          onSelect(p);
        },
      ),
    );
  }

  Future<void> _openAddonsPicker() async {
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => _AddonsPicker(
        catalog: widget.catalog,
        selected: cfg.bodyAddons,
        onChanged: (next) => setState(() => cfg = cfg.copyWith(bodyAddons: next)),
      ),
    );
  }

  static String _nicePath(String p) => p.split('/').last.replaceAll('.png', '').replaceAll('_', ' ');
  static int _indexOf(List<String> list, String v) => list.indexOf(v).clamp(0, list.isEmpty ? 0 : list.length - 1);
  static int _indexOfNullable(List<String?> list, String? v) => list.indexOf(v).clamp(0, list.isEmpty ? 0 : list.length - 1);

  static String _cyclePrev(List<String> list, String current) {
    final i = list.indexOf(current);
    final idx = i < 0 ? 0 : i;
    return list[(idx - 1 + list.length) % list.length];
  }

  static String _cycleNext(List<String> list, String current) {
    final i = list.indexOf(current);
    final idx = i < 0 ? 0 : i;
    return list[(idx + 1) % list.length];
  }

  static String? _cyclePrevNullable(List<String?> list, String? current) {
    final i = list.indexOf(current);
    final idx = i < 0 ? 0 : i;
    return list[(idx - 1 + list.length) % list.length];
  }

  static String? _cycleNextNullable(List<String?> list, String? current) {
    final i = list.indexOf(current);
    final idx = i < 0 ? 0 : i;
    return list[(idx + 1) % list.length];
  }
}

class _RowDoubleCycle extends StatelessWidget {
  final _MiniCycle left;
  final _MiniCycle right;

  const _RowDoubleCycle({
    required this.left,
    required this.right,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final maxW = c.maxWidth;
        final contentW = (maxW * 0.92).clamp(280.0, 520.0);

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: contentW),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              margin: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  Expanded(child: left),
                  Container(
                    width: 1,
                    height: 64,
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    color: Colors.white12,
                  ),
                  Expanded(child: right),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MiniCycle extends StatelessWidget {
  final String label;
  final String value;
  final String countText;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final VoidCallback? onTap;

  const _MiniCycle({
    required this.label,
    required this.value,
    required this.countText,
    required this.onPrev,
    required this.onNext,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: onPrev,
                  icon: const Icon(Icons.chevron_left),
                  splashRadius: 18,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                ),
                const SizedBox(width: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 140),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        countText,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(.55)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  onPressed: onNext,
                  icon: const Icon(Icons.chevron_right),
                  splashRadius: 18,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StripPicker extends StatelessWidget {
  final String title;
  final List<String> items;
  final String selected;
  final ValueChanged<String> onSelect;

  const _StripPicker({
    required this.title,
    required this.items,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190,
      child: Column(
        children: [
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final p = items[i];
                final isSel = p == selected;
                return InkWell(
                  onTap: () => onSelect(p),
                  child: Container(
                    width: 86,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(width: isSel ? 2 : 1, color: isSel ? Colors.white : Colors.white24),
                    ),
                    child: Image.asset(p, filterQuality: FilterQuality.none),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class _StripPickerNullable extends StatelessWidget {
  final String title;
  final List<String?> items;
  final String? selected;
  final ValueChanged<String?> onSelect;

  const _StripPickerNullable({
    required this.title,
    required this.items,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190,
      child: Column(
        children: [
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final p = items[i];
                final isSel = p == selected;
                return InkWell(
                  onTap: () => onSelect(p),
                  child: Container(
                    width: 86,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(width: isSel ? 2 : 1, color: isSel ? Colors.white : Colors.white24),
                    ),
                    child: p == null ? const Center(child: Text("None")) : Image.asset(p, filterQuality: FilterQuality.none),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class _AddonsPicker extends StatelessWidget {
  final AvatarCatalog catalog;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  const _AddonsPicker({
    required this.catalog,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final types = catalog.bodyAddonsByType.keys.toList()..sort();

    if (types.isEmpty) {
      return const SizedBox(height: 180, child: Center(child: Text('No hay add-ons')));
    }

    return SizedBox(
      height: 360,
      child: ListView.builder(
        itemCount: types.length,
        itemBuilder: (_, i) {
          final type = types[i];
          final items = catalog.bodyAddonsByType[type] ?? [];
          return ExpansionTile(
            title: Text(type, style: const TextStyle(fontWeight: FontWeight.w900)),
            children: [
              SizedBox(
                height: 96,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, j) {
                    final p = items[j];
                    final isSel = selected.contains(p);
                    return InkWell(
                      onTap: () {
                        final next = List<String>.from(selected);
                        if (isSel) {
                          next.remove(p);
                        } else {
                          next.add(p);
                        }
                        onChanged(next);
                      },
                      child: Container(
                        width: 76,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(width: isSel ? 2 : 1, color: isSel ? Colors.white : Colors.white24),
                        ),
                        child: Image.asset(p, filterQuality: FilterQuality.none),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 6),
            ],
          );
        },
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _ColorDot({required this.color, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 8),
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: selected ? Colors.white : Colors.transparent, width: 2),
        ),
      ),
    );
  }
}
