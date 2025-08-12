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
