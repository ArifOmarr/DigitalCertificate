import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'certificate_upload_screen.dart';

class RecipientDashboard extends StatelessWidget {
  const RecipientDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    debugPrint('Current User UID: $userId');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipient Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!context.mounted) return;
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body:
          userId == null
              ? const Center(child: Text('User not logged in.'))
              : StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('certificates')
                        .where(
                          'recipientEmail',
                          isEqualTo: FirebaseAuth.instance.currentUser?.email,
                        )
                        .orderBy('date', descending: true)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No certificates found.\nYour issued certificates will appear here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                    );
                  }

                  final docs = snapshot.data!.docs;

                  return Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final cert = docs[index];
                        final title = cert['title'] ?? 'Untitled Certificate';
                        final date = cert['date'] ?? 'Unknown date';
                        final fileUrl = cert['fileUrl'] ?? '';

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: const Icon(
                              Icons.picture_as_pdf,
                              color: Colors.red,
                            ),
                            title: Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text('Issued on: $date'),
                            trailing:
                                fileUrl.isNotEmpty
                                    ? IconButton(
                                      icon: const Icon(Icons.open_in_new),
                                      tooltip: 'View Certificate',
                                      onPressed: () {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Certificate URL: $fileUrl',
                                            ),
                                          ),
                                        );
                                      },
                                    )
                                    : null,
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CertificateUploadScreen(),
            ),
          );
        },
        tooltip: 'Upload Certificate',
        child: const Icon(Icons.upload_file),
      ),
    );
  }
}
