import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum UserType {
  client,
  professional,
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Register with email and password
  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
    required String name,
    required String phone,
    required UserType userType,
    String? description,
    List<String>? categories,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Create user document in Firestore
        await _firestore.collection('users').doc(credential.user!.uid).set({
          'email': email,
          'name': name,
          'phone': phone,
          'userType': userType.toString(),
          'createdAt': FieldValue.serverTimestamp(),
          if (description != null) 'description': description,
          if (categories != null) 'categories': categories,
        });

        // Update display name
        await credential.user!.updateDisplayName(name);
      }

      return credential;
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Get user type
  Future<UserType> getUserType(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data()?['userType'] == UserType.professional.toString()
          ? UserType.professional
          : UserType.client;
    } catch (e) {
      throw Exception('Error fetching user type: $e');
    }
  }

  // Update user profile
  Future<void> updateProfile({
    String? name,
    String? phone,
    String? description,
    List<String>? categories,
    String? photoURL,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      final updates = <String, dynamic>{};
      if (name != null) {
        updates['name'] = name;
        await user.updateDisplayName(name);
      }
      if (phone != null) updates['phone'] = phone;
      if (description != null) updates['description'] = description;
      if (categories != null) updates['categories'] = categories;
      if (photoURL != null) {
        updates['photoURL'] = photoURL;
        await user.updatePhotoURL(photoURL);
      }

      if (updates.isNotEmpty) {
        await _firestore.collection('users').doc(user.uid).update(updates);
      }
    } catch (e) {
      throw Exception('Error updating profile: $e');
    }
  }

  // Handle authentication exceptions
  String _handleAuthException(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          return 'No user found with this email.';
        case 'wrong-password':
          return 'Wrong password provided.';
        case 'email-already-in-use':
          return 'Email is already registered.';
        case 'invalid-email':
          return 'Invalid email address.';
        case 'weak-password':
          return 'Password is too weak.';
        case 'operation-not-allowed':
          return 'Operation not allowed.';
        default:
          return 'Authentication error: ${e.message}';
      }
    }
    return 'An error occurred: $e';
  }
}

// Provider
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// Auth state provider
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

// User type provider
final userTypeProvider = FutureProvider.family<UserType, String>((ref, uid) {
  return ref.watch(authServiceProvider).getUserType(uid);
});
