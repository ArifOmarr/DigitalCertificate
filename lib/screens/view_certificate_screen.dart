import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ViewCertificateScreen extends StatefulWidget {
  final String linkId;

  const ViewCertificateScreen({super.key, required this.linkId});

  @override
  State<ViewCertificateScreen> createState() => _ViewCertificateScreenState();
}

class _ViewCertificateScreenState extends State<ViewCertificateScreen> {
  final _otpController = TextEditingController();
  String? statusMessage;
  Map<String, dynamic>? certificateData;

  Future<void> verifyOtp() async {
    final doc = await FirebaseFirestore.instance
        .collection('shared_links')
        .doc(widget.linkId)
        .get();

    if (!doc.exists) {
      setState(() {
        statusMessage = "Invalid or expired link.";
      });
      return;
    }

    final data = doc.data()!;
    final now = DateTime.now();

    if ((data['expiresAt'] as Timestamp).toDate().isBefore(now)) {
      setState(() {
        statusMessage = "Link has expired.";
      });
      return;
    }

    if (data['otp'] != _otpController.text) {
      setState(() {
        statusMessage = "Invalid OTP.";
      });
      return;
    }

    // Fetch and display certificate (simulate with dummy info)
    setState(() {
      statusMessage = "OTP verified. Loading certificate...";
      certificateData = {
        "certificateId": data['certificateId'],
        "issuedTo": data['recipientEmail']
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("View Certificate")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _otpController,
              decoration: InputDecoration(labelText: "Enter OTP"),
              keyboardType: TextInputType.number,
            ),
            ElevatedButton(
              onPressed: verifyOtp,
              child: Text("Verify"),
            ),
            if (statusMessage != null) Text(statusMessage!),
            if (certificateData != null) ...[
              SizedBox(height: 20),
              Text("Certificate ID: ${certificateData!['certificateId']}"),
              Text("Issued to: ${certificateData!['issuedTo']}"),
            ]
          ],
        ),
      ),
    );
  }
}
