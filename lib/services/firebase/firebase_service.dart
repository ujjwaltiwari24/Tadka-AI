import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  FirestoreService._();

  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static Future<Map<String, dynamic>?> getGeminiConfig() async {
    try {
      final snapshot = await _firestore
          .collection('app_config')
          .doc('gemini')
          .get();

      if (!snapshot.exists) {
        throw Exception('Gemini configuration not found.');
      }

      return snapshot.data();
    } on FirebaseException catch (e) {
      throw Exception(
        'Firestore error: ${e.code} - ${e.message}',
      );
    }
  }
}