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
            elevation: 16,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 24),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 36.0,
                vertical: 40,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo/Icon (use built-in Icon instead of SvgPicture)
                  Container(
                    margin: const EdgeInsets.only(bottom: 18),
                    child: Icon(Icons.verified, size: 64, color: Colors.teal),
                  ),
                  Text(
                    'Digital Certificate',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.teal[900],
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Sign in to manage your certificates',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.teal[700],
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 36),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.login, size: 24),
                      label: const Text(
                        'Sign in with Google',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.teal,
                        shadowColor: Colors.teal.withOpacity(0.2),
                        elevation: 4,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        side: const BorderSide(color: Colors.teal, width: 2),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                      ).copyWith(
                        overlayColor: MaterialStateProperty.resolveWith<Color?>(
                          (Set<MaterialState> states) {
                            if (states.contains(MaterialState.hovered)) {
                              return Colors.teal.withOpacity(0.08);
                            }
                            return null;
                          },
                        ),
                      ),
                      onPressed: () => _handleLogin(context),
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
