import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CertificateDetailsScreen extends StatefulWidget {
  final String certificateId;
  const CertificateDetailsScreen({required this.certificateId, super.key});

  @override
  State<CertificateDetailsScreen> createState() => _CertificateDetailsScreenState();
}

class _CertificateDetailsScreenState extends State<CertificateDetailsScreen> {
  Map<String, dynamic>? _certificate;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchCertificate();
  }

  Future<void> _fetchCertificate() async {
    final doc = await FirebaseFirestore.instance.collection('certificates').doc(widget.certificateId).get();
    if (doc.exists) {
      setState(() {
        _certificate = doc.data();
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Certificate not found.')));
    }
  }

  Future<void> _revokeCertificate() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Revocation'),
        content: const Text('Are you sure you want to revoke this certificate? This action cannot be undone.'),
        actions: [
          TextButton(child: const Text('Cancel'), onPressed: () => Navigator.pop(context, false)),
          ElevatedButton(child: const Text('Revoke'), onPressed: () => Navigator.pop(context, true)),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('certificates').doc(widget.certificateId).update({
        'revoked': true,
      });
      setState(() => _certificate!['revoked'] = true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Certificate revoked.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_certificate == null) {
      return const Scaffold(body: Center(child: Text('Certificate not found.')));
    }

    final cert = _certificate!;
    final revoked = cert['revoked'] == true;

    return Scaffold(
      appBar: AppBar(title: const Text('Certificate Details'), backgroundColor: Colors.teal),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Title: ${cert['title'] ?? ''}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Recipient: ${cert['recipientEmail'] ?? ''}'),
            Text('Issuer: ${cert['issuer'] ?? ''}'),
            Text('Issue Date: ${cert['issueDate'] != null ? (cert['issueDate'] as Timestamp).toDate().toString().split(' ')[0] : ''}'),
            const SizedBox(height: 16),
            if (revoked)
              const Chip(label: Text('Revoked'), backgroundColor: Colors.redAccent)
            else
              ElevatedButton.icon(
                icon: const Icon(Icons.block),
                label: const Text('Revoke Certificate'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: _revokeCertificate,
              ),
          ],
        ),
      ),
    );
  }
}
