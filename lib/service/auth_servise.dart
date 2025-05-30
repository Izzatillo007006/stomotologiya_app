// auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Kirish-chiqish holatini kuzatish uchun stream
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  // Email va parol bilan kirish
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } catch (e) {
      rethrow;  // Xatoni oshkor qilish uchun qaytaradi
    }
  }

  // Email va parol bilan ro'yxatdan o'tish
  Future<User?> signUpWithEmailAndPassword(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } catch (e) {
      rethrow;
    }
  }

  // Chiqish funksiyasi
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
