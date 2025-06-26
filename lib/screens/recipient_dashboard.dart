import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RecipientDashboard extends StatelessWidget {
  const RecipientDashboard({super.key});

  Future<String?> _getRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    return doc.data()?['role'] as String?;
  }

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  void _goToCertificates(BuildContext context) {
    Navigator.pushNamed(context, '/recipient_certificates');
  }

  void _goToUpload(BuildContext context) {
    Navigator.pushNamed(context, '/recipient_upload');
  }

  void _showRequestDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final _formKey = GlobalKey<FormState>();
        String? _purpose;
        return AlertDialog(
          title: const Text('Request New Certificate'),
          content: Form(
            key: _formKey,
            child: TextFormField(
              decoration: const InputDecoration(labelText: 'Purpose/Reason'),
              validator: (v) => v == null || v.isEmpty ? 'Enter purpose' : null,
              onSaved: (v) => _purpose = v,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState?.validate() ?? false) {
                  _formKey.currentState?.save();
                  final user = FirebaseAuth.instance.currentUser;
                  await FirebaseFirestore.instance.collection('certificate_requests').add({
                    'requestedBy': user?.email,
                    'purpose': _purpose,
                    'requestedAt': FieldValue.serverTimestamp(),
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Request submitted!')),
                  );
                }
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipient Dashboard'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: FutureBuilder<String?>(
        future: _getRole(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data != 'recipient') {
            return const Center(child: Text('Access denied.'));
          }
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text('Welcome, Recipient!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.folder),
                label: const Text('View & Manage My Certificates'),
                onPressed: () => _goToCertificates(context),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.request_page),
                label: const Text('Request New Certificate'),
                onPressed: () => _showRequestDialog(context),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.upload_file),
                label: const Text('Upload Physical Certificate'),
                onPressed: () => _goToUpload(context),
              ),
            ],
          );
        },
      ),
    );
  }
} 