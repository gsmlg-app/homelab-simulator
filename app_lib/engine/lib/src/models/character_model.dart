import 'package:equatable/equatable.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:game_asset_characters/game_asset_characters.dart';

/// Character model representing a player's saved character
class CharacterModel extends Equatable {
  final String id;
  final String name;
  final Gender gender;
  final SkinTone skinTone;
  final HairStyle hairStyle;
  final HairColor hairColor;
  final OutfitVariant outfitVariant;
  final DateTime createdAt;
  final DateTime lastPlayedAt;
  final int totalPlayTime; // in seconds
  final int level;
  final int credits;

  const CharacterModel({
    required this.id,
    required this.name,
    required this.gender,
    this.skinTone = SkinTone.medium,
    this.hairStyle = HairStyle.short,
    this.hairColor = HairColor.brown,
    this.outfitVariant = OutfitVariant.casual,
    required this.createdAt,
    required this.lastPlayedAt,
    this.totalPlayTime = 0,
    this.level = 1,
    this.credits = GameConstants.startingCredits,
  });

  /// Get the sprite asset path for this character's gender
  String get spritePath =>
      gender == Gender.male ? GameCharacters.mainMale.path : GameCharacters.mainFemale.path;

  CharacterModel copyWith({
    String? id,
    String? name,
    Gender? gender,
    SkinTone? skinTone,
    HairStyle? hairStyle,
    HairColor? hairColor,
    OutfitVariant? outfitVariant,
    DateTime? createdAt,
    DateTime? lastPlayedAt,
    int? totalPlayTime,
    int? level,
    int? credits,
  }) {
    return CharacterModel(
      id: id ?? this.id,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      skinTone: skinTone ?? this.skinTone,
      hairStyle: hairStyle ?? this.hairStyle,
      hairColor: hairColor ?? this.hairColor,
      outfitVariant: outfitVariant ?? this.outfitVariant,
      createdAt: createdAt ?? this.createdAt,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      totalPlayTime: totalPlayTime ?? this.totalPlayTime,
      level: level ?? this.level,
      credits: credits ?? this.credits,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'gender': gender.name,
        'skinTone': skinTone.name,
        'hairStyle': hairStyle.name,
        'hairColor': hairColor.name,
        'outfitVariant': outfitVariant.name,
        'createdAt': createdAt.toIso8601String(),
        'lastPlayedAt': lastPlayedAt.toIso8601String(),
        'totalPlayTime': totalPlayTime,
        'level': level,
        'credits': credits,
      };

  factory CharacterModel.fromJson(Map<String, dynamic> json) {
    return CharacterModel(
      id: json['id'] as String,
      name: json['name'] as String,
      gender: json['gender'] != null
          ? Gender.values.byName(json['gender'] as String)
          : Gender.male,
      skinTone: json['skinTone'] != null
          ? SkinTone.values.byName(json['skinTone'] as String)
          : SkinTone.medium,
      hairStyle: json['hairStyle'] != null
          ? HairStyle.values.byName(json['hairStyle'] as String)
          : HairStyle.short,
      hairColor: json['hairColor'] != null
          ? HairColor.values.byName(json['hairColor'] as String)
          : HairColor.brown,
      outfitVariant: json['outfitVariant'] != null
          ? OutfitVariant.values.byName(json['outfitVariant'] as String)
          : OutfitVariant.casual,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastPlayedAt: DateTime.parse(json['lastPlayedAt'] as String),
      totalPlayTime: json['totalPlayTime'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      credits: json['credits'] as int? ?? GameConstants.startingCredits,
    );
  }

  factory CharacterModel.create({
    required String name,
    required Gender gender,
    SkinTone skinTone = SkinTone.medium,
    HairStyle hairStyle = HairStyle.short,
    HairColor hairColor = HairColor.brown,
    OutfitVariant outfitVariant = OutfitVariant.casual,
  }) {
    final now = DateTime.now();
    return CharacterModel(
      id: generateCharacterId(),
      name: name,
      gender: gender,
      skinTone: skinTone,
      hairStyle: hairStyle,
      hairColor: hairColor,
      outfitVariant: outfitVariant,
      createdAt: now,
      lastPlayedAt: now,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        gender,
        skinTone,
        hairStyle,
        hairColor,
        outfitVariant,
        createdAt,
        lastPlayedAt,
        totalPlayTime,
        level,
        credits,
      ];
}
