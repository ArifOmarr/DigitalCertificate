import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CaCertificateApprovalScreen extends StatelessWidget {
  const CaCertificateApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Certificate Approvals'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('physical_certificate_uploads')
            .where('status', isEqualTo: 'Pending Verification')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No pending certificates.'));
          }
          final docs = snapshot.data!.docs;
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final commentController = TextEditingController();
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Name: ${data['name'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('Purpose: ${data['purpose'] ?? ''}'),
                      Text('Date: ${data['date'] != null ? data['date'].toString().split(' ')[0] : ''}'),
                      Text('Uploaded by: ${data['uploadedBy'] ?? ''}'),
                      const SizedBox(height: 8),
                      if (data['fileUrl'] != null)
                        TextButton(
                          onPressed: () {
                            // Open the file URL
                            // You can use url_launcher for mobile/web
                          },
                          child: const Text('View Document'),
                        ),
                      TextField(
                        controller: commentController,
                        decoration: const InputDecoration(
                          labelText: 'Comment (optional)',
                        ),
                        minLines: 1,
                        maxLines: 3,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () async {
                              await doc.reference.update({
                                'status': 'Rejected',
                                'caComment': commentController.text,
                                'reviewedAt': FieldValue.serverTimestamp(),
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Certificate rejected.')),
                              );
                            },
                            child: const Text('Reject', style: TextStyle(color: Colors.red)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () async {
                              await doc.reference.update({
                                'status': 'Approved',
                                'caComment': commentController.text,
                                'reviewedAt': FieldValue.serverTimestamp(),
                              });
                              // Copy to certificates collection
                              final certData = {
                                'title': data['name'] ?? 'Physical Certificate',
                                'recipientEmail': data['uploadedBy'],
                                'pdfUrl': data['fileUrl'],
                                'purpose': data['purpose'],
                                'issuer': 'CA',
                                'status': 'Valid',
                                'createdAt': FieldValue.serverTimestamp(),
                                'source': 'physical_upload',
                              };
                              await FirebaseFirestore.instance.collection('certificates').add(certData);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Certificate approved.')),
                              );
                            },
                            child: const Text('Approve'),
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