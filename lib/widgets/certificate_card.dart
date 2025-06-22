import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CertificateCard extends StatelessWidget {
  final QueryDocumentSnapshot data;
  const CertificateCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(10),
      child: ListTile(
        title: Text(data['title']),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Organization: ${data['organization']}"),
            Text("Issued: ${data['issueDate']}"),
            Text("Expires: ${data['expiryDate']}"),
          ],
        ),
        trailing: const Icon(Icons.picture_as_pdf),
      ),
    );
  }
}
