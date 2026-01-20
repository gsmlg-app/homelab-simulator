import 'dart:math';

/// Validation result for character names
class NameValidationResult {
  final bool isValid;
  final String? errorMessage;

  const NameValidationResult.valid() : isValid = true, errorMessage = null;
  const NameValidationResult.invalid(this.errorMessage) : isValid = false;
}

/// Character name validation constants
class CharacterNameConstants {
  static const int minLength = 2;
  static const int maxLength = 16;

  static const Set<String> reservedWords = {
    'admin',
    'system',
    'root',
    'null',
    'undefined',
    'test',
    'default',
    'player',
    'user',
    'guest',
  };

  static const Set<String> blockedWords = {
    'ass',
    'damn',
    'hell',
    'crap',
    'shit',
    'fuck',
    'bitch',
    'bastard',
    'dick',
    'cock',
    'pussy',
    'slut',
    'whore',
    'nigger',
    'faggot',
    'retard',
  };
}

/// Validates a character name against all rules
NameValidationResult validateCharacterName(String name) {
  final trimmed = name.trim();

  if (trimmed.isEmpty) {
    return const NameValidationResult.invalid('Name cannot be empty');
  }

  if (trimmed.length < CharacterNameConstants.minLength) {
    return const NameValidationResult.invalid(
      'Name must be at least 2 characters',
    );
  }

  if (trimmed.length > CharacterNameConstants.maxLength) {
    return const NameValidationResult.invalid(
      'Name cannot exceed 16 characters',
    );
  }

  final lowerName = trimmed.toLowerCase();

  if (CharacterNameConstants.reservedWords.contains(lowerName)) {
    return const NameValidationResult.invalid('This name is reserved');
  }

  for (final word in CharacterNameConstants.blockedWords) {
    if (lowerName.contains(word)) {
      return const NameValidationResult.invalid(
        'Name contains inappropriate content',
      );
    }
  }

  return const NameValidationResult.valid();
}

/// Random name generator for character creation
class CharacterNameGenerator {
  static final _random = Random();

  static const List<String> _prefixes = [
    'Cyber',
    'Neo',
    'Data',
    'Byte',
    'Cloud',
    'Tech',
    'Net',
    'Pixel',
    'Nano',
    'Quantum',
    'Alpha',
    'Beta',
    'Gamma',
    'Delta',
    'Sigma',
    'Omega',
  ];

  static const List<String> _suffixes = [
    'Runner',
    'Walker',
    'Keeper',
    'Master',
    'Lord',
    'Knight',
    'Wizard',
    'Ninja',
    'Hero',
    'Hunter',
    'Scout',
    'Pilot',
    'Ops',
    'Admin',
    'Dev',
    'Hack',
  ];

  static const List<String> _names = [
    'Alex',
    'Blake',
    'Casey',
    'Dana',
    'Echo',
    'Finn',
    'Gray',
    'Harper',
    'Indigo',
    'Jordan',
    'Kai',
    'Luna',
    'Morgan',
    'Nova',
    'Onyx',
    'Phoenix',
    'Quinn',
    'River',
    'Sage',
    'Taylor',
    'Vex',
    'Winter',
    'Xen',
    'Yuri',
    'Zephyr',
  ];

  static String generate() {
    final style = _random.nextInt(3);
    switch (style) {
      case 0:
        // Prefix + Suffix: e.g., "CyberRunner"
        return '${_prefixes[_random.nextInt(_prefixes.length)]}${_suffixes[_random.nextInt(_suffixes.length)]}';
      case 1:
        // Name + Numbers: e.g., "Nova42"
        return '${_names[_random.nextInt(_names.length)]}${_random.nextInt(99) + 1}';
      default:
        // Just a name: e.g., "Phoenix"
        return _names[_random.nextInt(_names.length)];
    }
  }
}
