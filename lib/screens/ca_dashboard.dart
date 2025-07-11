import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CaDashboard extends StatelessWidget {
  const CaDashboard({super.key});

  Future<String?> _getRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
    return doc.data()?['role'] as String?;
  }

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  void _goToCreateCertificate(BuildContext context) {
    Navigator.pushNamed(context, '/ca_dashboard/create_certificate');
  }

  void _goToCertifyTrueCopies(BuildContext context) {
    Navigator.pushNamed(context, '/ca_approvals');
  }

  void _showCertificateRequests(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          builder: (context, scrollController) {
            return StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('certificate_requests')
                      .orderBy('requestedAt', descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(child: Text('No certificate requests.'));
                }
                return ListView.builder(
                  controller: scrollController,
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final status = data['status'] ?? 'Pending';
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        title: Text(
                          'Requested by: ${data['requestedBy'] ?? ''}',
                        ),
                        subtitle: Text(
                          'Purpose: ${data['purpose'] ?? ''}\nRequested at: ${data['requestedAt'] != null ? data['requestedAt'].toDate().toString().split(' ')[0] : ''}\nStatus: $status',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (status != 'Complete')
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () async {
                                  await doc.reference.update({
                                    'status': 'Complete',
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Marked as complete.'),
                                    ),
                                  );
                                },
                                child: const Text('Mark Complete'),
                              ),
                            if (status == 'Complete')
                              const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: Colors.teal[50],
      appBar: AppBar(
        title: const Text('CA Dashboard'),
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
          if (snapshot.data != 'ca') {
            return const Center(child: Text('Access denied.'));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.teal[200],
                      child: Icon(Icons.verified, color: Colors.white),
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
                  icon: const Icon(Icons.add),
                  label: const Text('Create/Issue Certificate'),
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
                  onPressed: () => _goToCreateCertificate(context),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.verified),
                  label: const Text('Certify True Copies'),
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
                  onPressed: () => _goToCertifyTrueCopies(context),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.request_page),
                  label: const Text('View Certificate Requests'),
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
                  onPressed: () => _showCertificateRequests(context),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Other Features:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  '• Add recipient name, organization, purpose, issue/expiry dates.',
                ),
                const Text('• Generate or upload certificate PDFs.'),
                const Text(
                  '• Digitally sign certificates (watermark/signature).',
                ),
                const Text(
                  '• Share certificates using secure, token-protected links.',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
