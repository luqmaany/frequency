import 'package:flutter/material.dart';

enum CategoryType {
  free,
  premium,
  seasonal,
  custom,
}

class Category {
  final String id;
  final String displayName;
  final Color color;
  final IconData icon;
  final String description;
  final List<Word> words;
  final CategoryType type;
  final bool isUnlocked;
  final String? imageAsset;

  const Category({
    required this.id,
    required this.displayName,
    required this.color,
    required this.icon,
    required this.description,
    required this.words,
    required this.type,
    this.isUnlocked = false,
    this.imageAsset,
  });

  // Convenience getters
  bool get isFree => type == CategoryType.free;
  bool get isPremium => type == CategoryType.premium;
  bool get isSeasonal => type == CategoryType.seasonal;
  bool get isCustom => type == CategoryType.custom;

  // Convenience methods
  int get wordCount => words.length;

  List<Word> getUnusedWords(Set<String> usedWords) {
    return words.where((word) => !usedWords.contains(word.text)).toList();
  }

  Word? getRandomWord(Set<String> usedWords) {
    final unusedWords = getUnusedWords(usedWords);
    if (unusedWords.isEmpty) return null;
    unusedWords.shuffle();
    return unusedWords.first;
  }
}

class Word {
  final String text;
  final String categoryId;
  final WordStats stats;

  const Word({
    required this.text,
    required this.categoryId,
    this.stats = const WordStats(),
  });

  Word copyWith({
    String? text,
    String? categoryId,
    WordStats? stats,
  }) {
    return Word(
      text: text ?? this.text,
      categoryId: categoryId ?? this.categoryId,
      stats: stats ?? this.stats,
    );
  }
}

class WordStats {
  final int appearanceCount;
  final int skipCount;
  final int guessedCount;

  const WordStats({
    this.appearanceCount = 0,
    this.skipCount = 0,
    this.guessedCount = 0,
  });

  double get skipRate =>
      appearanceCount > 0 ? skipCount / appearanceCount : 0.0;
  double get successRate =>
      appearanceCount > 0 ? guessedCount / appearanceCount : 0.0;
}

// Firestore serialization helpers for Category and basic icon mapping.
extension CategoryMap on Category {
  Map<String, dynamic> toMap() => {
        'id': id,
        'displayName': displayName,
        'description': description,
        'type': type.name,
        'isUnlocked': isUnlocked,
        'color': color.value,
        'icon': _iconToString(icon),
        // Use imageAsset as a generic image field; may contain an asset path or URL
        'imageUrl': imageAsset,
        'words': words.map((w) => w.text).toList(),
      };

  static Category fromMap(Map<String, dynamic> map) {
    final String id = map['id'] as String;
    final List<String> rawWords =
        (map['words'] as List?)?.map((e) => (e as String)).toList() ?? const [];
    final List<Word> words =
        rawWords.map((text) => Word(text: text, categoryId: id)).toList();

    final String typeName = (map['type'] as String?) ?? 'free';
    final CategoryType type = CategoryType.values.firstWhere(
      (t) => t.name == typeName,
      orElse: () => CategoryType.free,
    );

    final int colorValue = (map['color'] as num?)?.toInt() ?? Colors.blue.value;
    final String iconName = (map['icon'] as String?) ?? 'category';

    return Category(
      id: id,
      displayName: (map['displayName'] as String?) ?? id,
      description: (map['description'] as String?) ?? '',
      type: type,
      isUnlocked: (map['isUnlocked'] as bool?) ?? false,
      color: Color(colorValue),
      icon: _iconFromString(iconName),
      words: words,
      // Accept URL or asset path under the same field name for simplicity
      imageAsset: map['imageUrl'] as String?,
    );
  }
}

String _iconToString(IconData icon) {
  if (icon == Icons.person) return 'person';
  if (icon == Icons.pets) return 'pets';
  if (icon == Icons.public) return 'public';
  if (icon == Icons.movie) return 'movie';
  if (icon == Icons.fastfood) return 'fastfood';
  if (icon == Icons.business) return 'business';
  if (icon == Icons.shuffle) return 'shuffle';
  if (icon == Icons.directions_run) return 'directions_run';
  return 'category';
}

IconData _iconFromString(String name) {
  switch (name) {
    case 'person':
      return Icons.person;
    case 'pets':
      return Icons.pets;
    case 'public':
      return Icons.public;
    case 'movie':
      return Icons.movie;
    case 'fastfood':
      return Icons.fastfood;
    case 'business':
      return Icons.business;
    case 'shuffle':
      return Icons.shuffle;
    case 'directions_run':
      return Icons.directions_run;
    default:
      return Icons.category;
  }
}
