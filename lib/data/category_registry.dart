import 'package:flutter/material.dart';
import '../models/category.dart';
import '../services/category_service.dart';
import '../services/storage_service.dart';
import 'word_lists.dart';

// TODO: Add dynamic category management methods (addCategory, removeCategory, updateCategory)
// to support runtime category creation and modification
class CategoryRegistry {
  // Free categories (built-in)
  static final Map<String, Category> _categories = {
    'person': Category(
      id: 'person',
      displayName: 'Person',
      color: Colors.blue,
      icon: Icons.person,
      description: 'Famous people, historical figures, and celebrities',
      words: WordLists.people
          .map((text) => Word(
                text: text,
                categoryId: 'person',
              ))
          .toList(),
      type: CategoryType.free,
      isUnlocked: true,
    ),
    'action': Category(
      id: 'action',
      displayName: 'Action',
      color: Colors.green,
      icon: Icons.directions_run,
      description: 'Verbs and activities',
      words: WordLists.actions
          .map((text) => Word(
                text: text,
                categoryId: 'action',
              ))
          .toList(),
      type: CategoryType.free,
      isUnlocked: true,
    ),
    'world': Category(
      id: 'world',
      displayName: 'World',
      color: Colors.orange,
      icon: Icons.public,
      description: 'Places, landmarks, and locations',
      words: WordLists.locations
          .map((text) => Word(
                text: text,
                categoryId: 'world',
              ))
          .toList(),
      type: CategoryType.free,
      isUnlocked: true,
    ),
    'random': Category(
      id: 'random',
      displayName: 'Random',
      color: Colors.purple,
      icon: Icons.shuffle,
      description: 'Miscellaneous objects and concepts',
      words: WordLists.random
          .map((text) => Word(
                text: text,
                categoryId: 'random',
              ))
          .toList(),
      type: CategoryType.free,
      isUnlocked: true,
    ),
    'animal': Category(
      id: 'animal',
      displayName: 'Animals',
      color: Colors.teal,
      icon: Icons.pets,
      description: 'Animals from around the world',
      words: WordLists.animals
          .map((text) => Word(
                text: text,
                categoryId: 'animal',
              ))
          .toList(),
      type: CategoryType.free,
      isUnlocked: true,
    ),
    'anime': Category(
      id: 'anime',
      displayName: 'Anime',
      color: Colors.yellow,
      icon: Icons.movie, // fallback icon if image fails
      description: 'Anime characters, shows, and terms',
      words: WordLists.anime
          .map((text) => Word(
                text: text,
                categoryId: 'anime',
              ))
          .toList(),
      type: CategoryType.premium,
      isUnlocked: true,
      imageAsset: 'assets/images/categories/naruto.png',
    ),
    'food': Category(
      id: 'food',
      displayName: 'Food',
      color: Colors.red,
      icon: Icons.fastfood,
      description: 'Foods, dishes, ingredients, and drinks',
      words: WordLists.foods
          .map((text) => Word(
                text: text,
                categoryId: 'food',
              ))
          .toList(),
      type: CategoryType.free,
      isUnlocked: true,
    ),
    'company': Category(
      id: 'company',
      displayName: 'Companies',
      color: Colors.indigo,
      icon: Icons.business,
      description: 'Brands and companies across industries',
      words: WordLists.companies
          .map((text) => Word(
                text: text,
                categoryId: 'company',
              ))
          .toList(),
      type: CategoryType.free,
      isUnlocked: true,
    ),
    'tv': Category(
      id: 'tv',
      displayName: 'Film',
      color: Colors.cyan,
      icon: Icons.movie,
      description: 'TV shows and movies',
      words: WordLists.films
          .map((text) => Word(
                text: text,
                categoryId: 'tv',
              ))
          .toList(),
      type: CategoryType.free,
      isUnlocked: true,
    ),
  };

  // Get all categories
  static Map<String, Category> get allCategories => _categories;

  // Offline cache key for dynamic categories
  static const String _cacheKey = 'categories_cache_v1';

  // Load dynamic categories from Firestore with local fallback cache
  static Future<void> loadDynamicCategories() async {
    try {
      print('🔄 Loading categories from Firebase...');
      final remote = await CategoryService.fetchAllOnce();
      print('✅ Successfully loaded ${remote.length} categories from Firebase');
      for (final category in remote) {
        print(
            '  - ${category.id}: ${category.displayName} (${category.words.length} words)');
      }
      _merge(remote);
      await StorageService.saveObject(_cacheKey, {
        'items': remote.map((c) => c.toMap()).toList(),
      });
    } catch (e) {
      print('❌ Error loading categories from Firebase: $e');
      final cached = await StorageService.loadObject(_cacheKey);
      final items = (cached?['items'] as List?) ?? const [];
      print('📱 Loading ${items.length} categories from cache...');
      final fromCache = items
          .map((m) => CategoryMap.fromMap(Map<String, dynamic>.from(m)))
          .toList();
      _merge(fromCache);
    }
  }

  static void _merge(List<Category> dynamicCategories) {
    for (final c in dynamicCategories) {
      _categories[c.id] = c;
    }
  }

  static Future<void> upsertCategory(Category category) async {
    await CategoryService.upsert(category);
    _categories[category.id] = category;
  }

  static Future<void> removeCategory(String id) async {
    await CategoryService.delete(id);
    _categories.remove(id);
  }

  // Get category by ID
  static Category getCategory(String categoryId) {
    return _categories[categoryId] ?? _categories['person']!;
  }

  // Get all categories as a list
  static List<Category> getAllCategories() {
    return _categories.values.toList();
  }

  // Get all category IDs
  static List<String> getAllCategoryIds() {
    return _categories.keys.toList();
  }

  // Get only free categories
  static List<Category> getFreeCategories() {
    return _categories.values
        .where((category) => category.type == CategoryType.free)
        .toList();
  }

  // Get unlocked categories. If purchasedCategoryIds is provided, include those too.
  static List<Category> getUnlockedCategories([
    List<String>? purchasedCategoryIds,
  ]) {
    final allCats = _categories.values.toList();
    if (purchasedCategoryIds == null) {
      return allCats.where((category) => category.isUnlocked).toList();
    }
    return allCats
        .where((category) =>
            category.isUnlocked || purchasedCategoryIds.contains(category.id))
        .toList();
  }

  static String getCategoryFromDisplayName(String displayName) {
    return _categories.values
        .firstWhere((category) => category.displayName == displayName)
        .id;
  }

  // Get category by display name
  static Category getCategoryByDisplayName(String displayName) {
    return _categories.values
        .firstWhere((category) => category.displayName == displayName);
  }

  // Get categories by their IDs
  static List<Category> getCategoriesByIds(List<String> categoryIds) {
    return categoryIds
        .map((id) => _categories[id])
        .where((category) => category != null)
        .cast<Category>()
        .toList();
  }

  // Get only unlocked categories by their IDs (useful for deck selection)
  static List<Category> getUnlockedCategoriesByIds(List<String> categoryIds,
      [List<String>? purchasedCategoryIds]) {
    final unlockedIds = purchasedCategoryIds ?? [];
    return categoryIds
        .map((id) => _categories[id])
        .where((category) =>
            category != null &&
            (category.isUnlocked || unlockedIds.contains(category.id)))
        .cast<Category>()
        .toList();
  }
}
