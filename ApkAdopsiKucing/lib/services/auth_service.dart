import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sign up with email & password
  Future<User?> signUpWithEmailPassword(
    String email,
    String password,
    String name,
    String username,
    String phone,
  ) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      User? user = userCredential.user;
      // } on FirebaseAuthException catch (e) {
      //   print("Error during sign up: ${e.message}");
      //   return null;
      if (user != null) {
        // Simpan data pengguna tambahan ke Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': email,
          'name': name,
          'username': username,
          'phone': phone,
          'createdAt': Timestamp.now(), // Opsional: tambahkan timestamp
        });
      }
      return user;
    } on FirebaseAuthException catch (e) {
      print("Error during sign up: ${e.message}");
      // Anda bisa melemparkan error ini atau mengembalikan null
      throw e; // Melemparkan error agar bisa ditangkap di UI
    } catch (e) {
      print("Error during sign up: $e");
      throw e; // Melemparkan error generik
    }
  }

  // Sign in with email & password
  Future<User?> signInWithEmailPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print("Error during sign in: ${e.message}");
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
