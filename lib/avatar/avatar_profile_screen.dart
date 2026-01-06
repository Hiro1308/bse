import 'dart:io';
import 'package:flutter/material.dart';
import 'avatar_assets.dart';
import 'avatar_model.dart';
import 'avatar_storage.dart';
import 'avatar_editor_screen.dart';
import 'avatar_preview.dart';

class AvatarProfileScreen extends StatefulWidget {
  const AvatarProfileScreen({super.key});

  @override
  State<AvatarProfileScreen> createState() => _AvatarProfileScreenState();
}

class _AvatarProfileScreenState extends State<AvatarProfileScreen> {
  AvatarCatalog? catalog;
  AvatarConfig? cfg;
  String? avatarImagePath;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final c = await AvatarAssets.load();
    final loadedCfg = await AvatarStorage.loadConfig();
    final imgPath = await AvatarStorage.loadAvatarImagePath();

    // config default si no existe
    final defaultCfg = loadedCfg ?? _defaultConfig(c);

    setState(() {
      catalog = c;
      cfg = defaultCfg;
      avatarImagePath = imgPath;
    });
  }

  AvatarConfig _defaultConfig(AvatarCatalog c) {
    final gender = "male";
    final bodyIdle = c.bodyMaleIdle ?? "";
    final bodyBase = (c.bodyMaleBases.isNotEmpty) ? c.bodyMaleBases.first : "";

    return AvatarConfig(
      bodyGender: gender,
      bodyIdle: bodyIdle,
      bodyBase: bodyBase,
      bodyAddons: const [],
      head: c.heads.isNotEmpty ? c.heads.first : "",
      hair: c.hairs.isNotEmpty ? c.hairs.first : "",
      eyes: c.eyes.isNotEmpty ? c.eyes.first : "",
      clothes: c.clothes.isNotEmpty ? c.clothes.first : "",
      accessory: c.accessories.isNotEmpty ? c.accessories.first : null,
      skinColor: 0xFFF2C6A0, 
      facingRow: 2,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (catalog == null || cfg == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final hasFile = avatarImagePath != null && File(avatarImagePath!).existsSync();

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil (BSE)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Avatar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white12),
              ),
              child: hasFile
                  ? Image.file(File(avatarImagePath!), width: 200, height: 200, filterQuality: FilterQuality.none)
                  : AvatarPreview(cfg: cfg!, size: 200),
            ),

            const SizedBox(height: 16),

            FilledButton.icon(
              onPressed: () async {
                final updated = await Navigator.push<AvatarConfig>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AvatarEditorScreen(catalog: catalog!, initial: cfg!),
                  ),
                );

                if (updated != null) {
                  // recargar config + path
                  final imgPath = await AvatarStorage.loadAvatarImagePath();
                  setState(() {
                    cfg = updated;
                    avatarImagePath = imgPath;
                  });
                }
              },
              icon: const Icon(Icons.edit),
              label: const Text('Editar personaje'),
            ),
          ],
        ),
      ),
    );
  }
}
