import 'package:cloud_firestore/cloud_firestore.dart';

/// Schéma du document `users/{userId}` :
/// {
///   "userId": "UID_FIREBASE_AUTH",
///   "titulairePrenom": "Sophie",
///   "titulaireNom": "Martin",
///   "produitsOuverts": [
///     {
///       "nomProduit": "Livret A",
///       "soldeInitial": 150.0,
///       "dateOuverture": "10/09/2026"
///
///     }
///   ],
///   "updatedAt": FieldValue.serverTimestamp()
/// }
///
class ManageDbService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static final ManageDbService _instance = ManageDbService._internal();
  factory ManageDbService() => _instance;
  ManageDbService._internal();

  static const String _usersCollection = 'users';

  Future<void> saveUserRecord({
    required String userId,
    required String titulairePrenom,
    required String titulaireNom,
    required String nomProduit,
    required double soldeInitial,
  }) async {
    try {
      final userDocRef = _db.collection(_usersCollection).doc(userId);
      final now = DateTime.now();
      final dateStr =
          "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";

      final newProductMap = {
        'nomProduit': nomProduit,
        'soldeInitial': soldeInitial,
        'dateOuverture': dateStr,
      };

      await userDocRef.set({
        'userId': userId,
        'titulairePrenom': titulairePrenom,
        'titulaireNom': titulaireNom,
        'produitsOuverts': FieldValue.arrayUnion([newProductMap]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getUserRecord(String userId) async {
    try {
      final docSnapshot = await _db
          .collection(_usersCollection)
          .doc(userId)
          .get();
      if (docSnapshot.exists && docSnapshot.data() != null) {
        return docSnapshot.data();
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> streamUserRecord(
    String userId,
  ) {
    return _db.collection(_usersCollection).doc(userId).snapshots();
  }
}
