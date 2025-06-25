import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TrueCopyApprovalScreen extends StatelessWidget {
  const TrueCopyApprovalScreen({Key? key}) : super(key: key);

  Future<void> _updateStatus(
    BuildContext context,
    String docId,
    String status,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('true_copy_requests')
          .doc(docId)
          .update({'status': status});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Request ${status == "approved" ? "approved" : "rejected"}',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('True Copy Approval Requests')),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('true_copy_requests')
                .where('status', isEqualTo: 'pending')
                .orderBy('upload_date', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No pending requests.'));
          }

          final requests = snapshot.data!.docs;
          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final doc = requests[index];
              final data = doc.data() as Map<String, dynamic>;
              final recipientName = data['recipient_name'] ?? 'Unknown';
              final documentTitle = data['document_title'] ?? 'Untitled';
              final uploadDate =
                  data['upload_date'] != null
                      ? (data['upload_date'] as Timestamp).toDate()
                      : null;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(documentTitle),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Recipient: $recipientName'),
                      if (uploadDate != null)
                        Text('Uploaded: ${uploadDate.toLocal()}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        tooltip: 'Approve',
                        onPressed:
                            () => _updateStatus(context, doc.id, 'approved'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        tooltip: 'Reject',
                        onPressed:
                            () => _updateStatus(context, doc.id, 'rejected'),
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
