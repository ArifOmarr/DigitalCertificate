import 'package:flutter/material.dart';
import '../models/certificate.dart';
import 'package:intl/intl.dart';

class CertificateDisplayScreen extends StatelessWidget {
  final Certificate certificate;

  const CertificateDisplayScreen({super.key, required this.certificate});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff0f0f0),
      appBar: AppBar(
        title: const Text('Issued Certificate'),
        backgroundColor: Colors.teal[700],
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.black87, width: 3),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(4, 6),
              ),
            ],
          ),
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              // Title
              Text(
                'Certificate of Achievement',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal[800],
                  letterSpacing: 1.2,
                  shadows: [
                    Shadow(color: Colors.grey.shade400, blurRadius: 2),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              const Divider(thickness: 1.5),

              const SizedBox(height: 16),
              const Text(
                'This certificate is proudly presented to',
                style: TextStyle(fontSize: 16),
              ),

              const SizedBox(height: 24),

              // Name
              Text(
                certificate.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),

              const SizedBox(height: 16),

              // Purpose
              Text(
                'For: ${certificate.purpose}',
                style: const TextStyle(fontSize: 16),
              ),

              const SizedBox(height: 6),

              // Organization
              Text(
                'Organization: ${certificate.organization}',
                style: const TextStyle(fontSize: 16),
              ),

              const SizedBox(height: 24),
              const Divider(thickness: 1),

              const SizedBox(height: 12),

              // Dates
              Text(
                'Issued: ${DateFormat.yMMMd().format(certificate.issueDate)}',
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              ),
              Text(
                'Expires: ${DateFormat.yMMMd().format(certificate.expiryDate)}',
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              ),

              const SizedBox(height: 36),

              // Signature
              Text(
                '~ CA Signature ~',
                style: TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  color: Colors.teal[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
