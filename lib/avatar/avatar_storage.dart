import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'avatar_model.dart';

class AvatarStorage {
  static const _configKey = 'bse_avatar_config';
  static const _imagePathKey = 'bse_avatar_image_path';

  static Future<void> saveConfig(AvatarConfig cfg) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_configKey, cfg.toJsonString());
  }

  static Future<AvatarConfig?> loadConfig() async {
    final sp = await SharedPreferences.getInstance();
    final s = sp.getString(_configKey);
    if (s == null || s.isEmpty) return null;
    return AvatarConfig.fromJsonString(s);
  }

  static Future<String?> loadAvatarImagePath() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_imagePathKey);
  }

  static Future<String> saveAvatarImageLocally(Uint8List pngBytes) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/bse_avatar.png');
    await file.writeAsBytes(pngBytes, flush: true);

    final sp = await SharedPreferences.getInstance();
    await sp.setString(_imagePathKey, file.path);

    return file.path;
  }
}
