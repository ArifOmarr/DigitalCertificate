import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ViewerDashboard extends StatelessWidget {
  const ViewerDashboard({super.key});

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  void _goToSharedCertificates(BuildContext context) {
    // TODO: Implement shared certificates screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Shared Certificates coming soon!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: Colors.teal[50],
      appBar: AppBar(
        title: const Text('Viewer Dashboard'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.teal[200],
                  child: Icon(Icons.visibility, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Welcome, ${user?.email ?? ''}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.visibility),
              label: const Text('View Shared Certificates'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => _goToSharedCertificates(context),
            ),
            const SizedBox(height: 32),
            const Text(
              'Viewer Features:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('• View certificates shared with you.'),
            const Text('• Verify certificate authenticity.'),
          ],
        ),
      ),
    );
  }
}
