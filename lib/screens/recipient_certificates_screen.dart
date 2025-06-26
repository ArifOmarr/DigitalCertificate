import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/certificate_share_service.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:open_file/open_file.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class RecipientCertificatesScreen extends StatelessWidget {
  const RecipientCertificatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Not logged in.')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.teal[50],
      appBar: AppBar(
        title: const Text('My Certificates'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('certificates')
            .where('recipientEmail', isEqualTo: user.email)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.school, size: 64, color: Colors.teal[200]),
                  const SizedBox(height: 16),
                  const Text('No certificates found.', style: TextStyle(fontSize: 18)),
                ],
              ),
            );
          }
          final certificates = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: certificates.length,
            itemBuilder: (context, index) {
              final doc = certificates[index];
              final cert = doc.data() as Map<String, dynamic>;
              final issueDate = (cert['issueDate'] as Timestamp?)?.toDate();
              final status = cert['status'] ?? 'Unknown';
              Color statusColor = Colors.orange;
              if (status == 'Valid') statusColor = Colors.green;
              if (status == 'Expired') statusColor = Colors.red;
              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                margin: const EdgeInsets.only(bottom: 20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.school, color: Colors.teal, size: 40),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(cert['title'] ?? 'No Title', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(
                              'Issued: ${issueDate != null ? issueDate.toString().split(' ')[0] : 'Unknown'}',
                              style: const TextStyle(fontSize: 14, color: Colors.black54),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Chip(
                                  label: Text(status),
                                  backgroundColor: statusColor.withOpacity(0.15),
                                  labelStyle: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.share, color: Colors.teal),
                            tooltip: 'Share Certificate',
                            onPressed: () async {
                              final token = await CertificateShareService().createShareableLink(
                                doc.id,
                                expireDays: 3, // You can make this configurable
                                oneTime: false, // Or true for one-time use
                              );
                              // Development/Production switch for share link
                              const bool isProduction = false; // Set to true when deploying!
                              const localDomain = 'http://10.113.19.22:3000'; // Your local IP and port
                              const productionDomain = 'https://mycertificates.upm.edu.my'; // Real domain
                              final link = '${isProduction ? productionDomain : localDomain}/#/shared/$token';
                              await Clipboard.setData(ClipboardData(text: link));
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  title: const Text('Shareable Link'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Link copied to clipboard!'),
                                      const SizedBox(height: 8),
                                      SelectableText(link),
                                      const SizedBox(height: 16),
                                      const Text('This link will expire in 3 days.'),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Close'),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.teal,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      onPressed: () async {
                                        Navigator.pop(context);
                                        final uri = Uri.parse(link);
                                        if (await canLaunchUrl(uri)) {
                                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Could not open link in browser')),
                                          );
                                        }
                                      },
                                      child: const Text('Open Link'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.visibility, color: Colors.blue),
                            tooltip: 'View Certificate',
                            onPressed: () async {
                              final url = cert['pdfUrl'];
                              if (url != null && url.isNotEmpty) {
                                await openPdfFromUrl(url, context);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('No PDF URL available for this certificate.')),
                                );
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.download, color: Colors.green),
                            tooltip: 'Download Certificate',
                            onPressed: () async {
                              final url = cert['pdfUrl'];
                              if (url != null && url.isNotEmpty) {
                                await openPdfFromUrl(url, context);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('No PDF URL available for this certificate.')),
                                );
                              }
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

  Future<void> openPdfFromUrl(String url, BuildContext context) async {
    try {
      if (kIsWeb) {
        // Web: Open in new tab
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open PDF in browser')),
          );
        }
      } else {
        // Mobile: Download and open with local app
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final bytes = response.bodyBytes;
          final dir = await getTemporaryDirectory();
          final file = File('${dir.path}/temp_${DateTime.now().millisecondsSinceEpoch}.pdf');
          await file.writeAsBytes(bytes);
          await OpenFile.open(file.path);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to download PDF.')),
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