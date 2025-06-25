import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class ShareCertificateScreen extends StatefulWidget {
  final String certificateId;
  final String recipientEmail;

  const ShareCertificateScreen({super.key, 
    required this.certificateId,
    required this.recipientEmail,
  });

  @override
  _ShareCertificateScreenState createState() => _ShareCertificateScreenState();
}

class _ShareCertificateScreenState extends State<ShareCertificateScreen> {
  String? generatedLink;
  String? generatedOtp;

  Future<void> generateSecureLink() async {
    final otp = (Random().nextInt(900000) + 100000).toString(); // 6-digit OTP
    final linkId = DateTime.now().millisecondsSinceEpoch.toString();
    final linkUrl = 'https://yourapp.com/view/$linkId';

    await FirebaseFirestore.instance.collection('shared_links').doc(linkId).set({
      'certificateId': widget.certificateId,
      'otp': otp,
      'expiresAt': DateTime.now().add(Duration(hours: 24)),
      'createdAt': DateTime.now(),
      'recipientEmail': widget.recipientEmail,
      'isUsed': false,
    });

    setState(() {
      generatedLink = linkUrl;
      generatedOtp = otp;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff0f0f0),
      appBar: AppBar(
        title: const Text("Generate Secure Link"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: generateSecureLink,
              child: const Text("Generate Secure Link"),
            ),
            if (generatedLink != null) ...[
              const SizedBox(height: 20),
              Text("Share this link: $generatedLink"),
              Text("OTP: $generatedOtp"),
            ]
          ],
        ),
      ),
    );
  }
}
