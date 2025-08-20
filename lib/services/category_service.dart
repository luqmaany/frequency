import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category.dart';

class CategoryService {
  static final CollectionReference<Map<String, dynamic>> _collection =
      FirebaseFirestore.instance.collection('categories');

  static Future<List<Category>> fetchAllOnce() async {
    final snapshot = await _collection.get();
    return snapshot.docs
        .map((doc) => CategoryMap.fromMap({
              'id': doc.id,
              ...doc.data(),
            }))
        .toList();
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
