import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category.dart';

class CategoryService {
  static final CollectionReference<Map<String, dynamic>> _collection =
      FirebaseFirestore.instance.collection('categories');

  static Future<List<Category>> fetchAllOnce() async {
    final snapshot = await _collection.get();
    print(
        '📄 Found ${snapshot.docs.length} documents in Firestore categories collection');

    final List<Category> categories = [];
    for (final doc in snapshot.docs) {
      try {
        final data = {
          'id': doc.id,
          ...doc.data(),
        };
        print('🔍 Processing document: ${doc.id}');
        print('   Data: $data');

        final category = CategoryMap.fromMap(data);
        categories.add(category);
        print('   ✅ Successfully parsed category: ${category.displayName}');
      } catch (e) {
        print('   ❌ Error parsing document ${doc.id}: $e');
        print('   Raw data: ${doc.data()}');
      }
    }

    return categories;
  }

  static Stream<List<Category>> streamAll() {
    return _collection.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => CategoryMap.fromMap({
              'id': doc.id,
              ...doc.data(),
            }))
        .toList());
  }

  static Future<void> upsert(Category category) async {
    await _collection
        .doc(category.id)
        .set(category.toMap(), SetOptions(merge: true));
  }

  static Future<void> delete(String id) async {
    await _collection.doc(id).delete();
  }
}
