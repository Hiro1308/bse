import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class AvatarAsset {
  final String path;
  final List<String> parts; // ej: ["hair","curtains","adult"]
  final String file;        // ej: "black.png"

  AvatarAsset({required this.path, required this.parts, required this.file});

  factory AvatarAsset.fromJson(Map<String, dynamic> j) => AvatarAsset(
    path: j['path'] as String,
    parts: (j['parts'] as List).cast<String>(),
    file: j['file'] as String,
  );
}

class AvatarManifest {
  final List<AvatarAsset> items;
  AvatarManifest(this.items);

  static Future<AvatarManifest> load() async {
    final raw = await rootBundle.loadString('assets/avatar_manifest.json');
    final jsonMap = json.decode(raw) as Map<String, dynamic>;
    final list = (jsonMap['items'] as List)
        .map((e) => AvatarAsset.fromJson(e as Map<String, dynamic>))
        .toList();
    return AvatarManifest(list);
  }

  /// partsPrefix: ej ["hair","curtains","adult"] o ["tshirt","male"]
  List<String> pathsWherePrefix(List<String> partsPrefix) {
    return items
        .where((a) =>
            a.parts.length >= partsPrefix.length &&
            _startsWith(a.parts, partsPrefix))
        .map((a) => a.path)
        .toList();
  }

  static bool _startsWith(List<String> a, List<String> prefix) {
    for (var i = 0; i < prefix.length; i++) {
      if (a[i] != prefix[i]) return false;
    }
    return true;
  }
}