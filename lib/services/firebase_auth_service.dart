import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final String uid = user.uid;
        debugPrint('User ID: $uid');
      }
      debugPrint('FirebaseAuthException [signIn]: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Erreur inattendue [signIn]: $e');
      rethrow;
    }
  }

  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException [signUp]: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Erreur inattendue [signUp]: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
