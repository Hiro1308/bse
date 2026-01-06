import 'dart:convert';

class AvatarConfig {
  // body
  final String bodyGender; // "male" | "female"
  final String bodyBase;   // path asset (png) o "" si usas solo idle + tint
  final String bodyIdle;   // path asset para idle base (opcional)
  final List<String> bodyAddons; // paths asset

  // head / layers
  final String? head;      // nullable (none)
  final String? hair;      // nullable (none)
  final String eyes;       // asset path (required)
  final String clothes;    // asset path (puede ser "" para none)
  final String? accessory; // asset path nullable

  // view
  final int facingRow;     // 0..N-1 (rotación / dirección)

  // (lo dejamos por compatibilidad, aunque lo saques de UI)
  final int skinColor;     // ARGB int

  AvatarConfig({
    required this.bodyGender,
    required this.bodyBase,
    required this.bodyIdle,
    required this.bodyAddons,
    required this.head,
    required this.hair,
    required this.eyes,
    required this.clothes,
    required this.accessory,
    required this.facingRow,
    required this.skinColor,
  });

  Map<String, dynamic> toJson() => {
        "bodyGender": bodyGender,
        "bodyBase": bodyBase,
        "bodyIdle": bodyIdle,
        "bodyAddons": bodyAddons,
        "head": head,
        "hair": hair,
        "eyes": eyes,
        "clothes": clothes,
        "accessory": accessory,
        "facingRow": facingRow,
        "skinColor": skinColor,
      };

  static AvatarConfig fromJson(Map<String, dynamic> j) => AvatarConfig(
        bodyGender: (j["bodyGender"] ?? "male") as String,
        bodyBase: (j["bodyBase"] ?? "") as String,
        bodyIdle: (j["bodyIdle"] ?? "") as String,
        bodyAddons: ((j["bodyAddons"] ?? const []) as List).cast<String>(),
        head: (j["head"] as String?)?.trim().isEmpty == true ? null : j["head"] as String?,
        hair: (j["hair"] as String?)?.trim().isEmpty == true ? null : j["hair"] as String?,
        eyes: (j["eyes"] ?? "") as String,
        clothes: (j["clothes"] ?? "") as String,
        accessory: (j["accessory"] as String?)?.trim().isEmpty == true ? null : j["accessory"] as String?,
        facingRow: (j["facingRow"] ?? 2) as int,
        skinColor: (j["skinColor"] ?? 0xFFF2C6A0) as int,
      );

  String toJsonString() => jsonEncode(toJson());
  static AvatarConfig fromJsonString(String s) => fromJson(jsonDecode(s) as Map<String, dynamic>);

    static const _unset = Object();

  AvatarConfig copyWith({
    String? bodyGender,
    String? bodyBase,
    String? bodyIdle,
    List<String>? bodyAddons,

    Object? head = _unset,      // String? | null | _unset
    Object? hair = _unset,      // String? | null | _unset
    String? eyes,
    String? clothes,
    Object? accessory = _unset, // String? | null | _unset

    int? facingRow,
    int? skinColor,
  }) {
    return AvatarConfig(
      bodyGender: bodyGender ?? this.bodyGender,
      bodyBase: bodyBase ?? this.bodyBase,
      bodyIdle: bodyIdle ?? this.bodyIdle,
      bodyAddons: bodyAddons ?? List<String>.from(this.bodyAddons),

      head: identical(head, _unset) ? this.head : head as String?,
      hair: identical(hair, _unset) ? this.hair : hair as String?,
      eyes: eyes ?? this.eyes,
      clothes: clothes ?? this.clothes,
      accessory: identical(accessory, _unset) ? this.accessory : accessory as String?,

      facingRow: facingRow ?? this.facingRow,
      skinColor: skinColor ?? this.skinColor,
    );
  }

}
