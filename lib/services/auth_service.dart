import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign up with email and password
  Future<UserCredential?> createUserWithEmailAndPassword(String email, String password, String role) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      
      // Create user document in Firestore
      await _firestore.collection('users').doc(credential.user!.uid).set({
        'email': email,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'profileComplete': false,
      });
      
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // Update last logout time
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'lastLogoutAt': FieldValue.serverTimestamp(),
          'isActive': false,
        });
      }
      await _auth.signOut();
      await _googleSignIn.signOut();
    } catch (e) {
      print('Error during sign out: $e');
      // Still sign out even if update fails
      await _auth.signOut();
      await _googleSignIn.signOut();
    }
  }

  // Get user role from Firestore
  Future<String?> getUserRole(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data()?['role'];
    } catch (e) {
      return null;
    }
  }

  // Get user profile data
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data();
    } catch (e) {
      return null;
    }
  }

  // Update user profile
  Future<void> updateUserProfile(String uid, Map<String, dynamic> profileData) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        ...profileData,
        'updatedAt': FieldValue.serverTimestamp(),
        'profileComplete': true,
      });
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // Check if user session is valid
  Future<bool> isSessionValid() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    
    try {
      // Check if user token is still valid
      await user.getIdToken(true);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Update last login time
  Future<void> updateLastLogin(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'loginCount': FieldValue.increment(1),
      });
    } catch (e) {
      print('Error updating last login: $e');
    }
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return 'Authentication failed: ${e.message}';
    }
  }

  Future<String?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null;
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;
      if (user == null) {
        return null;
      }
      // Restrict to UPM email addresses only (allow both @upm.edu.my and @student.upm.edu.my)
      if (user.email == null ||
          !(user.email!.toLowerCase().endsWith('@upm.edu.my') ||
            user.email!.toLowerCase().endsWith('@student.upm.edu.my'))
      ) {
        await _auth.signOut();
        await _googleSignIn.signOut();
        return null;
      }
      // Fetch user role from Firestore
      final docRef = _firestore.collection('users').doc(user.uid);
      final doc = await docRef.get();
      if (doc.exists && doc.data() != null && doc.data()!.containsKey('role')) {
        // Update last login time
        await updateLastLogin(user.uid);
        return doc['role'] as String;
      } else if (!doc.exists) {
        await docRef.set({
          'email': user.email,
          'role': 'recipient',
          'createdAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
          'isActive': true,
          'profileComplete': false,
          'loginCount': 1,
        });
        return 'recipient';
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // Check if user has completed profile
  Future<bool> isProfileComplete(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data()?['profileComplete'] ?? false;
    } catch (e) {
      return false;
    }
  }

  // Get user activity status
  Future<bool> isUserActive(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data()?['isActive'] ?? false;
    } catch (e) {
      return false;
    }
  }
}
