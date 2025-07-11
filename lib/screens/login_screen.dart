import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'donation_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleLogin(BuildContext context) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final googleSignIn = GoogleSignIn();
    final auth = FirebaseAuth.instance;
    final firestore = FirebaseFirestore.instance;

    try {
      await googleSignIn.signOut(); // Force account picker
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Sign-in cancelled.';
        });
        return;
      }

      // Restrict to UPM domain
      final email = googleUser.email.toLowerCase();
      if (!(email.endsWith('@upm.edu.my') || email.endsWith('@student.upm.edu.my'))) {
        await googleSignIn.signOut();
        setState(() {
          _isLoading = false;
          _errorMessage = 'Only @upm.edu.my emails are allowed.';
        });
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
        setState(() {
          _isLoading = false;
          _errorMessage = 'Sign-in failed.';
        });
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
        setState(() {
          _isLoading = false;
        });
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => RoleSelectionScreen(user: user, docRef: docRef),
          ),
        );
        return;
      }

      setState(() {
        _isLoading = false;
      });

      // Navigate based on role
      if (role == 'ca') {
        Navigator.pushReplacementNamed(context, '/ca_dashboard');
      } else if (role == 'recipient') {
        Navigator.pushReplacementNamed(context, '/recipient_dashboard');
      } else if (role == 'admin') {
        Navigator.pushReplacementNamed(context, '/admin_dashboard');
      } else if (role == 'viewer') {
        Navigator.pushReplacementNamed(context, '/viewer_dashboard');
      } else {
        setState(() {
          _errorMessage = 'Unknown role: $role';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Login error: $e';
      });
    }
  }

  void _navigateToDonation(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DonationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal[50],
      body: Center(
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          margin: const EdgeInsets.symmetric(horizontal: 32),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Add your logo to assets and uncomment the next line
                // Image.asset('assets/logo.png', height: 80),
                const SizedBox(height: 16),
                Text(
                  'Digital Certificate',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('Sign in to manage your certificates'),
                const SizedBox(height: 32),
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red[600], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red[700], fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ElevatedButton.icon(
                  icon: _isLoading 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.login),
                  label: Text(_isLoading ? 'Signing in...' : 'Sign in with Google'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    disabledBackgroundColor: Colors.teal[300],
                  ),
                  onPressed: _isLoading ? null : () => _handleLogin(context),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  icon: const Icon(Icons.favorite, color: Colors.red),
                  label: const Text('Support Our Project'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red[600],
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  onPressed: _isLoading ? null : () => _navigateToDonation(context),
                ),
                const SizedBox(height: 16),
                Text(
                  'UPM Students & Staff Only',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
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
  const RoleSelectionScreen({required this.user, required this.docRef, super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String? _selectedRole;
  bool _saving = false;
  String? _errorMessage;

  void _saveRole() async {
    if (_selectedRole == null) return;
    setState(() {
      _saving = true;
      _errorMessage = null;
    });
    
    try {
      await widget.docRef.set({
        'email': widget.user.email,
        'role': _selectedRole,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'profileComplete': false,
        'loginCount': 1,
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
    } catch (e) {
      setState(() {
        _saving = false;
        _errorMessage = 'Failed to save role: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal[50],
      body: Center(
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          margin: const EdgeInsets.symmetric(horizontal: 32),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Select Your Role',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Welcome, ${widget.user.email}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 24),
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red[600], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red[700], fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                RadioListTile<String>(
                  value: 'admin',
                  groupValue: _selectedRole,
                  onChanged: _saving ? null : (v) => setState(() => _selectedRole = v),
                  title: const Text('Admin'),
                  subtitle: const Text('System administrator with full access'),
                ),
                RadioListTile<String>(
                  value: 'ca',
                  groupValue: _selectedRole,
                  onChanged: _saving ? null : (v) => setState(() => _selectedRole = v),
                  title: const Text('Certificate Authority (CA)'),
                  subtitle: const Text('Create and issue certificates'),
                ),
                RadioListTile<String>(
                  value: 'recipient',
                  groupValue: _selectedRole,
                  onChanged: _saving ? null : (v) => setState(() => _selectedRole = v),
                  title: const Text('Recipient'),
                  subtitle: const Text('Receive and manage certificates'),
                ),
                RadioListTile<String>(
                  value: 'viewer',
                  groupValue: _selectedRole,
                  onChanged: _saving ? null : (v) => setState(() => _selectedRole = v),
                  title: const Text('Viewer'),
                  subtitle: const Text('View shared certificates'),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _saving || _selectedRole == null ? null : _saveRole,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _saving 
                    ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          ),
                          SizedBox(width: 8),
                          Text('Saving...'),
                        ],
                      )
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