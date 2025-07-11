import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  Future<void> _handleLogin(BuildContext context) async {
    final googleSignIn = GoogleSignIn();
    final auth = FirebaseAuth.instance;
    final firestore = FirebaseFirestore.instance;

    try {
      await googleSignIn.signOut(); // Force account picker
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Sign-in cancelled.')));
        return;
      }

      // Restrict to UPM domain
      final email = googleUser.email.toLowerCase();
      if (!(email.endsWith('@upm.edu.my') ||
          email.endsWith('@student.upm.edu.my'))) {
        await googleSignIn.signOut();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Only @upm.edu.my emails are allowed.')),
        );
        return;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Sign-in failed.')));
        return;
      }

      // Fetch user role in Firestore
      final docRef = firestore.collection('users').doc(user.uid);
      final doc = await docRef.get();
      String? role;
      if (doc.exists && doc.data() != null && doc.data()!.containsKey('role')) {
        role = doc['role'] as String?;
      }

      // If the email is not in the database (no user doc), show self-check/role selection
      if (!doc.exists || role == null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => RoleSelectionScreen(user: user, docRef: docRef),
          ),
        );
        return;
      }

      // Navigate based on role
      print('Role fetched: [$role]');
      if (role == 'ca') {
        Navigator.pushReplacementNamed(context, '/ca_dashboard');
      } else if (role == 'recipient') {
        Navigator.pushReplacementNamed(context, '/recipient_dashboard');
      } else if (role == 'admin') {
        Navigator.pushReplacementNamed(context, '/admin_dashboard');
      } else if (role == 'viewer') {
        Navigator.pushReplacementNamed(context, '/viewer_dashboard');
      } else if (role == 'client') {
        Navigator.pushReplacementNamed(context, '/client_dashboard');
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Unknown role: $role')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Login error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    print('LoginScreen build called');
    return Scaffold(
      // Gradient background
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFe0f7fa), Color(0xFFb2ebf2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Card(
            color: Colors.white,
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 24),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 28.0,
                vertical: 36,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Digital Certificate',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sign in to manage your certificates',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.login, size: 22),
                      label: const Text(
                        'Sign in with Google',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF009688),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 0,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: () => _handleLogin(context),
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/donation'),
                    icon: const Icon(Icons.favorite, color: Colors.red),
                    label: const Text(
                      'Support Our Project',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
                      minimumSize: Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      alignment: Alignment.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RoleSelectionScreen extends StatefulWidget {
  final User user;
  final DocumentReference docRef;
  const RoleSelectionScreen({
    required this.user,
    required this.docRef,
    super.key,
  });

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String? _selectedRole;
  bool _saving = false;

  void _saveRole() async {
    if (_selectedRole == null) return;
    setState(() => _saving = true);
    await widget.docRef.set({
      'email': widget.user.email,
      'role': _selectedRole,
      'createdAt': FieldValue.serverTimestamp(),
    });
    setState(() => _saving = false);
    // Navigate to dashboard
    if (_selectedRole == 'ca') {
      Navigator.pushReplacementNamed(context, '/ca_dashboard');
    } else if (_selectedRole == 'recipient') {
      Navigator.pushReplacementNamed(context, '/recipient_dashboard');
    } else if (_selectedRole == 'admin') {
      Navigator.pushReplacementNamed(context, '/admin_dashboard');
    } else if (_selectedRole == 'viewer') {
      Navigator.pushReplacementNamed(context, '/viewer_dashboard');
    } else if (_selectedRole == 'client') {
      Navigator.pushReplacementNamed(context, '/client_dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal[50],
      body: Center(
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 32),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Select Your Role',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                RadioListTile<String>(
                  value: 'admin',
                  groupValue: _selectedRole,
                  onChanged:
                      _saving ? null : (v) => setState(() => _selectedRole = v),
                  title: const Text('Admin'),
                ),
                RadioListTile<String>(
                  value: 'ca',
                  groupValue: _selectedRole,
                  onChanged:
                      _saving ? null : (v) => setState(() => _selectedRole = v),
                  title: const Text('Certificate Authority (CA)'),
                ),
                RadioListTile<String>(
                  value: 'recipient',
                  groupValue: _selectedRole,
                  onChanged:
                      _saving ? null : (v) => setState(() => _selectedRole = v),
                  title: const Text('Recipient'),
                ),
                RadioListTile<String>(
                  value: 'viewer',
                  groupValue: _selectedRole,
                  onChanged:
                      _saving ? null : (v) => setState(() => _selectedRole = v),
                  title: const Text('Viewer'),
                ),
                RadioListTile<String>(
                  value: 'client',
                  groupValue: _selectedRole,
                  onChanged: _saving ? null : (v) => setState(() => _selectedRole = v),
                  title: const Text('Client'),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed:
                      _saving || _selectedRole == null ? null : _saveRole,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child:
                      _saving
                          ? const CircularProgressIndicator()
                          : const Text('Continue'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
