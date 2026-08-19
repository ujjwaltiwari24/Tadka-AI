import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseTest {
  FirebaseTest._();

  static Future<String> testFirestoreConnection() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('app_config')
          .doc('gemini')
          .get();

      if (!snapshot.exists) {
        return 'DOCUMENT_NOT_FOUND';
      }

      final data = snapshot.data();

      if (data == null) {
        return 'DOCUMENT_DATA_EMPTY';
      }

      if (data['enabled'] != true) {
        return 'GEMINI_DISABLED';
      }

      if (data['model'] == null) {
        return 'MODEL_MISSING';
      }

      if (data['apiKey'] == null) {
        return 'API_KEY_MISSING';
      }

      return 'SUCCESS';
    } on FirebaseException catch (e) {
      return 'FIREBASE_ERROR: ${e.code} - ${e.message}';
    } catch (e) {
      return 'UNKNOWN_ERROR: $e';
    }
  }
}