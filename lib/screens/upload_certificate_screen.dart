import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UploadCertificateScreen extends StatefulWidget {
  const UploadCertificateScreen({super.key});

  @override
  State<UploadCertificateScreen> createState() =>
      _UploadCertificateScreenState();
}

class _UploadCertificateScreenState extends State<UploadCertificateScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _title = TextEditingController();
  final TextEditingController _org = TextEditingController();
  final TextEditingController _issueDate = TextEditingController();
  final TextEditingController _expiryDate = TextEditingController();

  void uploadCertificate() async {
    if (_formKey.currentState!.validate()) {
      final user = FirebaseAuth.instance.currentUser!;
      await FirebaseFirestore.instance.collection('certificates').add({
        'title': _title.text,
        'organization': _org.text,
        'issueDate': _issueDate.text,
        'expiryDate': _expiryDate.text,
        'recipientEmail': user.email,
      });
      if (!mounted) {
        return;
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Certificate')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _org,
                decoration: const InputDecoration(labelText: 'Organization'),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _issueDate,
                decoration: const InputDecoration(
                  labelText: 'Issue Date (YYYY-MM-DD)',
                ),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _expiryDate,
                decoration: const InputDecoration(
                  labelText: 'Expiry Date (YYYY-MM-DD)',
                ),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: uploadCertificate,
                child: const Text('Upload'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
