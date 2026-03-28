/// User-selectable accent family for [ColorScheme.fromSeed] + light surface overrides.
enum AppColorPreset {
  /// Warm stone / sand surfaces + amber-brown seed.
  earth,

  /// Warm blush surfaces + orange-red seed.
  fire,

  /// Cream paper + teal seed (forest / growth mood).
  forest,

  /// Cool blue-gray surfaces + sky blue seed (default).
  sky,
}

extension AppColorPresetLabels on AppColorPreset {
  String get shortLabel => switch (this) {
        AppColorPreset.earth => 'Earth',
        AppColorPreset.fire => 'Fire',
        AppColorPreset.forest => 'Forest',
        AppColorPreset.sky => 'Sky',
      };
}
