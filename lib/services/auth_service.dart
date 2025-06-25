import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> signInWithGoogle() async {
    try {
      print('[AuthService] Starting Google Sign-In');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print('[AuthService] Google Sign-In cancelled by user');
        return null;
      }
      print('[AuthService] Google user email: "+googleUser.email+"');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;
      if (user == null) {
        print('[AuthService] Firebase user is null after sign-in');
        return null;
      }
      print('[AuthService] Firebase user email: "+user.email+"');
      // Restrict to UPM email addresses only (allow both @upm.edu.my and @student.upm.edu.my)
      if (user.email == null ||
          !(user.email!.toLowerCase().endsWith('@upm.edu.my') ||
            user.email!.toLowerCase().endsWith('@student.upm.edu.my'))
      ) {
        print('[AuthService] Email does not match UPM domain: "+user.email+"');
        await _auth.signOut();
        await _googleSignIn.signOut();
        return null;
      }
      print('[AuthService] Email passed UPM check: "+user.email+"');
      // Fetch user role from Firestore
      final docRef = _firestore.collection('users').doc(user.uid);
      final doc = await docRef.get();
      if (doc.exists && doc.data() != null && doc.data()!.containsKey('role')) {
        print('[AuthService] User document exists with role: '+doc['role']);
        return doc['role'] as String;
      } else if (!doc.exists) {
        print('[AuthService] User document does not exist, creating new one');
        // Auto-create user document with default role 'recipient'
        await docRef.set({
          'email': user.email,
          'role': 'recipient',
          'createdAt': FieldValue.serverTimestamp(),
        });
        return 'recipient';
      } else {
        print('[AuthService] User document exists but no role field');
        return null;
      }
    } catch (e) {
      print('[AuthService] Google sign-in error: $e');
      return null;
    }
  }
}
