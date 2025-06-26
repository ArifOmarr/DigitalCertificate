import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import 'package:open_file/open_file.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class SharedCertificateScreen extends StatefulWidget {
  final String token;
  const SharedCertificateScreen({required this.token, super.key});

  @override
  State<SharedCertificateScreen> createState() => _SharedCertificateScreenState();
}

class _SharedCertificateScreenState extends State<SharedCertificateScreen> {
  Future<Map<String, dynamic>?>? _future;
  String? _otpInput;
  bool _otpRequired = false;
  String? _expectedOtp;
  Map<String, dynamic>? _cert;
  bool _otpVerified = false;

  @override
  void initState() {
    super.initState();
    _future = _validateAndFetchAndLog();
  }

  Future<Map<String, dynamic>?> _validateAndFetchAndLog() async {
    final doc = await FirebaseFirestore.instance.collection('shared_links').doc(widget.token).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    final now = DateTime.now();
    if (data['expiresAt'].toDate().isBefore(now)) return null;
    if (data['oneTime'] == true && data['used'] == true) return null;

    // OTP logic (optional)
    if (data['otp'] != null && data['otp'].toString().isNotEmpty) {
      setState(() {
        _otpRequired = true;
        _expectedOtp = data['otp'];
      });
    }

    // Mark as used if one-time
    if (data['oneTime'] == true && data['used'] == false) {
      await doc.reference.update({'used': true});
    }

    // Log access
    await FirebaseFirestore.instance.collection('shared_links').doc(widget.token).collection('access_logs').add({
      'timestamp': FieldValue.serverTimestamp(),
      'certificateId': data['certificateId'],
      'token': widget.token,
      'userAgent': kIsWeb ? 'web' : 'non-web',
    });

    // Fetch certificate
    final certDoc = await FirebaseFirestore.instance.collection('certificates').doc(data['certificateId']).get();
    if (!certDoc.exists) return null;
    return certDoc.data();
  }

  void _verifyOtp() {
    if (_otpInput == _expectedOtp) {
      setState(() {
        _otpVerified = true;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid OTP.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal[50],
      appBar: AppBar(
        title: const Text('Shared Certificate'),
        backgroundColor: Colors.teal,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.link_off, size: 64, color: Colors.teal[200]),
                  const SizedBox(height: 16),
                  const Text('Link expired or invalid.', style: TextStyle(fontSize: 18)),
                ],
              ),
            );
          }
          _cert = snapshot.data!;
          // OTP required and not yet verified
          if (_otpRequired && !_otpVerified) {
            return Center(
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                margin: const EdgeInsets.symmetric(horizontal: 32),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Enter OTP to view certificate:', style: TextStyle(fontSize: 18)),
                      const SizedBox(height: 24),
                      TextField(
                        decoration: const InputDecoration(labelText: 'OTP'),
                        onChanged: (v) => _otpInput = v,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _verifyOtp,
                        child: const Text('Verify'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          final cert = _cert!;
          final issuer = cert['issuer'] ?? 'Unknown Issuer';
          final signature = cert['signature'] ?? '';
          final isSigned = signature.isNotEmpty;
          return Center(
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Title: ${cert['title'] ?? ''}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        if (isSigned)
                          const Chip(label: Text('Digitally Signed'), backgroundColor: Colors.greenAccent),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Recipient: ${cert['recipientEmail'] ?? ''}'),
                    Text('Purpose: ${cert['purpose'] ?? ''}'),
                    Text('Issue Date: ${cert['issueDate'] != null ? (cert['issueDate'] is Timestamp ? cert['issueDate'].toDate().toString().split(' ')[0] : cert['issueDate'].toString()) : ''}'),
                    Text('Issuer: $issuer'),
                    if (isSigned)
                      Text('Signature: $signature', style: const TextStyle(fontSize: 12, color: Colors.green)),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('View Certificate PDF'),
                      onPressed: () async {
                        final pdfUrl = cert['pdfUrl'];
                        if (pdfUrl != null && pdfUrl.isNotEmpty) {
                          await _openPdfFromUrl(pdfUrl);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No PDF URL available for this certificate.')),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    const Text('This certificate is view-only. You cannot modify or re-share it.'),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openPdfFromUrl(String url) async {
    try {
      if (kIsWeb) {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open PDF in browser')),
          );
        }
      } else {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final bytes = response.bodyBytes;
          final dir = await getTemporaryDirectory();
          final file = File('${dir.path}/shared_cert_${DateTime.now().millisecondsSinceEpoch}.pdf');
          await file.writeAsBytes(bytes);
          await OpenFile.open(file.path);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to download PDF.')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening PDF: $e')),
      );
    }
  }
} 