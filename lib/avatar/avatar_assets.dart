import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AvatarCatalog {
  final List<String> bodyMaleBases;    // assets/avatar/body/base/male/*.png (menos idle.png si querés)
  final List<String> bodyFemaleBases;  // idem
  final String? bodyMaleIdle;          // assets/avatar/body/base/male/idle.png si existe
  final String? bodyFemaleIdle;

  final Map<String, List<String>> bodyAddonsByType; // tail -> [paths], wings -> [paths]

  final List<String> hairs;       // assets/avatar/hair/**/*.png
  final List<String> heads; // assets/avatar/head/**
  final List<String> eyes;        // assets/avatar/eyes/**/*.png
  final List<String> clothes;     // ropa/equipo (varias carpetas)
  final List<String> accessories; // accesorios/overlays (varias carpetas)

  AvatarCatalog({
    required this.bodyMaleBases,
    required this.bodyFemaleBases,
    required this.bodyMaleIdle,
    required this.bodyFemaleIdle,
    required this.bodyAddonsByType,
    required this.hairs,
    required this.heads,
    required this.eyes,
    required this.clothes,
    required this.accessories,
  });
}

class AvatarAssets {
  static Future<AvatarCatalog> load() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final all = manifest.listAssets();

    debugPrint("ALL ASSETS COUNT: ${all.length}");
    debugPrint("FIRST 20 ASSETS:\n${all.take(20).join('\n')}");

    final avatarOnly = all.where((p) => p.startsWith('assets/avatar/')).toList();
    debugPrint("AVATAR ASSETS COUNT: ${avatarOnly.length}");
    debugPrint("FIRST 20 AVATAR:\n${avatarOnly.take(20).join('\n')}");

    final keys = all.where((k) => k.toLowerCase().endsWith('.png')).toList();

    List<String> _byPrefix(String prefix) =>
        keys.where((k) => k.startsWith(prefix)).toList()..sort();

    // Body bases (si tu pack no tiene /body/base/male, quedará 0; está ok por ahora)
    final maleAll = _byPrefix('assets/avatar/body/base/male/');
    final femaleAll = _byPrefix('assets/avatar/body/base/female/');

    String? findIdle(List<String> list) {
      for (final p in list) {
        if (p.toLowerCase().endsWith('/idle.png')) return p;
      }
      return null;
    }

    final maleIdle = findIdle(maleAll);
    final femaleIdle = findIdle(femaleAll);

    final maleBases =
        maleAll.where((p) => !p.toLowerCase().endsWith('/idle.png')).toList();
    final femaleBases =
        femaleAll.where((p) => !p.toLowerCase().endsWith('/idle.png')).toList();

    // Addons (lo dejo tal cual lo tenías)
    final addonPrefix = 'assets/avatar/body/addons/';
    final addonKeys = keys
        .where((k) => k.startsWith(addonPrefix) && k.toLowerCase().endsWith('.png'))
        .toList();

    final Map<String, List<String>> addonsByType = {};
    for (final k in addonKeys) {
      final rest = k.substring(addonPrefix.length);
      final parts = rest.split('/');
      if (parts.isEmpty) continue;
      final type = parts.first;
      addonsByType.putIfAbsent(type, () => []).add(k);
    }
    for (final e in addonsByType.entries) {
      e.value.sort();
    }

    final hairs = _byPrefix('assets/avatar/hair/');
    final eyes = _byPrefix('assets/avatar/eyes/');
    final heads = _byPrefix('assets/avatar/head/heads/');

    // CLOTHES: mantenemos lo actual y SUMAMOS carpetas del pack
    final clothes = <String>[
      // lo que ya tenías
      ..._byPrefix("assets/avatar/tshirt/"),
      ..._byPrefix("assets/avatar/tshirt_buttoned/"),
      ..._byPrefix("assets/avatar/dress/"),
      ..._byPrefix("assets/avatar/pants/"),
      ..._byPrefix("assets/avatar/shoes/"),
      ..._byPrefix("assets/avatar/socks/"),

      // nuevas carpetas (según tu árbol)
      ..._byPrefix("assets/avatar/torso/"),
      ..._byPrefix("assets/avatar/legs/"),
      ..._byPrefix("assets/avatar/feet/"),
      ..._byPrefix("assets/avatar/arms/"),
      ..._byPrefix("assets/avatar/shoulders/"),
      ..._byPrefix("assets/avatar/hat/"),
      ..._byPrefix("assets/avatar/shield/"),
    ]..sort();

    // ACCESSORIES: mantenemos lo actual y SUMAMOS overlays
    final accessories = <String>[
      // lo que ya tenías
      ..._byPrefix("assets/avatar/glasses/"),
      ..._byPrefix("assets/avatar/monocle/"),
      ..._byPrefix("assets/avatar/masks/"),
      ..._byPrefix("assets/avatar/patches/"),
      ..._byPrefix("assets/avatar/headband/"),
      ..._byPrefix("assets/avatar/pirate/"),

      // nuevas carpetas (según tu árbol)
      ..._byPrefix("assets/avatar/beards/"),
      ..._byPrefix("assets/avatar/facial/"),
    ]..sort();

    return AvatarCatalog(
      bodyMaleBases: maleBases,
      bodyFemaleBases: femaleBases,
      bodyMaleIdle: maleIdle,
      bodyFemaleIdle: femaleIdle,
      bodyAddonsByType: addonsByType,
      hairs: hairs,
      heads: heads,
      eyes: eyes,
      clothes: clothes,
      accessories: accessories,
    );
  }
}
