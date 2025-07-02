import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ClientReviewCertificatesScreen extends StatelessWidget {
  const ClientReviewCertificatesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Not logged in')),
      );
    }

    print('Current user UID: ${user.uid}');

    final certsQuery = FirebaseFirestore.instance
        .collection('certificates')
        .where('clientId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'pending_review');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Certificates'),
        backgroundColor: Colors.teal,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: certsQuery.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No certificates to review.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }
          final certs = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: certs.length,
            itemBuilder: (context, index) {
              final cert = certs[index];
              final data = cert.data() as Map<String, dynamic>;
              final issuedDate = data['issuedDate'] is Timestamp
                  ? (data['issuedDate'] as Timestamp).toDate()
                  : null;
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: LinearGradient(
                    colors: [
                      Colors.teal.withOpacity(0.10),
                      Colors.tealAccent.withOpacity(0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: Colors.teal.shade200, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.teal.withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.verified, color: Colors.teal[400], size: 32),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              data['title'] ?? 'Certificate',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Issuer: ${data['issuerName'] ?? 'Unknown'}',
                        style: TextStyle(fontSize: 16, color: Colors.teal[900]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Issued: ${issuedDate != null ? "${issuedDate.toLocal()}".split(' ')[0] : '-'}',
                        style: TextStyle(fontSize: 16, color: Colors.teal[800]),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: Colors.teal[50],
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.teal.shade100),
                            ),
                            child: const Text(
                              'Pending Review',
                              style: TextStyle(
                                color: Colors.teal,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.check, color: Colors.white),
                            label: const Text('Approve'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 22, vertical: 14),
                              textStyle: const TextStyle(fontWeight: FontWeight.bold),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 2,
                            ),
                            onPressed: () async {
                              await cert.reference
                                  .update({'status': 'approved_by_client'});
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Certificate approved.')),
                              );
                            },
                          ),
                          const SizedBox(width: 18),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.close, color: Colors.white),
                            label: const Text('Reject'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 22, vertical: 14),
                              textStyle: const TextStyle(fontWeight: FontWeight.bold),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 2,
                            ),
                            onPressed: () async {
                              await cert.reference
                                  .update({'status': 'rejected_by_client'});
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Certificate rejected.')),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
} 