import 'package:equatable/equatable.dart';
import 'package:app_lib_core/app_lib_core.dart';

/// Character model representing a player's saved character
class CharacterModel extends Equatable {
  final String id;
  final String name;
  final Gender gender;
  final DateTime createdAt;
  final DateTime lastPlayedAt;
  final int totalPlayTime; // in seconds
  final int level;
  final int credits;

  const CharacterModel({
    required this.id,
    required this.name,
    required this.gender,
    required this.createdAt,
    required this.lastPlayedAt,
    this.totalPlayTime = 0,
    this.level = 1,
    this.credits = GameConstants.startingCredits,
  });

  /// Get the sprite asset path for this character's gender
  String get spritePath => gender == Gender.male
      ? 'packages/game_asset_sprites/assets/boy.png'
      : 'packages/game_asset_sprites/assets/girl.png';

  CharacterModel copyWith({
    String? id,
    String? name,
    Gender? gender,
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
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastPlayedAt: DateTime.parse(json['lastPlayedAt'] as String),
      totalPlayTime: json['totalPlayTime'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      credits: json['credits'] as int? ?? GameConstants.startingCredits,
    );
  }

  factory CharacterModel.create({required String name, required Gender gender}) {
    final now = DateTime.now();
    return CharacterModel(
      id: generateCharacterId(),
      name: name,
      gender: gender,
      createdAt: now,
      lastPlayedAt: now,
    );
  }

  @override
  List<Object?> get props => [id, name, gender, createdAt, lastPlayedAt, totalPlayTime, level, credits];
}
