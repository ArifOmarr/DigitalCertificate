import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ShareCertificateScreen extends StatefulWidget {
  final String certificateId;
  const ShareCertificateScreen({required this.certificateId, super.key});

  @override
  State<ShareCertificateScreen> createState() => _ShareCertificateScreenState();
}

class _ShareCertificateScreenState extends State<ShareCertificateScreen> {
  DateTime? _expiresAt;
  final TextEditingController _otpController = TextEditingController();
  bool _oneTime = false;
  String? _generatedLink;
  bool _loading = false;
  bool? _isRevoked;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _fetchCertificateStatusAndUserRole();
  }

  Future<void> _fetchCertificateStatusAndUserRole() async {
    final certDoc = await FirebaseFirestore.instance
        .collection('certificates')
        .doc(widget.certificateId)
        .get();

    if (certDoc.exists) {
      _isRevoked = certDoc['revoked'] == true;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        _userRole = userDoc['role'];
      }
    }

    setState(() {});
  }

  Future<void> _generateLink() async {
    if (_expiresAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an expiry date.')),
      );
      return;
    }

    setState(() {
      _loading = true;
    });

    final token = const Uuid().v4();
    final docRef =
        FirebaseFirestore.instance.collection('shared_links').doc(token);

    await docRef.set({
      'certificateId': widget.certificateId,
      'expiresAt': Timestamp.fromDate(_expiresAt!),
      'otp': _otpController.text.trim(),
      'oneTime': _oneTime,
      'used': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    final baseUrl =
        'https://your-app.web.app/shared/$token'; // Replace with actual domain
    setState(() {
      _generatedLink = baseUrl;
      _loading = false;
    });
  }

  Future<void> _confirmAndRevokeCertificate() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Revocation'),
        content: const Text(
            'Are you sure you want to revoke this certificate? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Revoke')),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('certificates')
            .doc(widget.certificateId)
            .update({'revoked': true});

        setState(() {
          _isRevoked = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Certificate revoked successfully.')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to revoke certificate: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Share Certificate'),
        backgroundColor: Colors.teal,
      ),
      body: _isRevoked == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero Banner
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.teal[300]!, Colors.teal[100]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                      child: Row(
                        children: [
                          Icon(Icons.link, size: 48, color: Colors.white),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Share Certificate',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Generate secure, time-limited links for certificate sharing.',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Sharing Preferences Card
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Set sharing preferences:',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
                            ),
                            const SizedBox(height: 16),
                            // Expiry Date Picker
                            Row(
                              children: [
                                const Text('Expires at:'),
                                const SizedBox(width: 16),
                                ElevatedButton(
                                  onPressed: () async {
                                    final now = DateTime.now();
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: now,
                                      firstDate: now,
                                      lastDate: now.add(const Duration(days: 365)),
                                    );
                                    if (picked != null) {
                                      setState(() {
                                        _expiresAt = picked;
                                      });
                                    }
                                  },
                                  child: Text(_expiresAt == null
                                      ? 'Select Date'
                                      : _expiresAt!.toString().split(' ')[0]),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // OTP Input
                            TextField(
                              controller: _otpController,
                              decoration: const InputDecoration(
                                labelText: 'Optional OTP',
                                hintText: 'Leave blank if not needed',
                              ),
                            ),
                            const SizedBox(height: 16),
                            // One-Time Toggle
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('One-time access?'),
                                Switch(
                                  value: _oneTime,
                                  onChanged: (val) => setState(() => _oneTime = val),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            // Generate Button
                            ElevatedButton.icon(
                              icon: const Icon(Icons.link),
                              label: const Text('Generate Share Link'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              ),
                              onPressed: (_loading || _isRevoked == true) ? null : _generateLink,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Generated Link Card
                    if (_generatedLink != null) ...[
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        color: Colors.teal[50],
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Shareable Link:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                              const SizedBox(height: 8),
                              SelectableText(
                                _generatedLink!,
                                style: const TextStyle(color: Colors.blueAccent),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.copy),
                                label: const Text('Copy Link'),
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: _generatedLink!));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Link copied to clipboard')),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Certificate Actions Card (if admin/ca)
                    if (_userRole == 'admin' || _userRole == 'ca') ...[
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        color: Colors.red[50],
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Certificate Actions:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.block),
                                label: const Text('Revoke Certificate'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                ),
                                onPressed: _confirmAndRevokeCertificate,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (_isRevoked == true) ...[
                      const Text(
                        '⚠️ This certificate has already been revoked.',
                        style: TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Tips/Info Section
                    Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      color: Colors.teal[100],
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: const [
                            Icon(Icons.lightbulb_outline, color: Colors.teal, size: 24),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Tip: Share links with an expiry date and OTP for maximum security.',
                                style: TextStyle(fontSize: 15, color: Colors.teal),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Footer
                    Center(
                      child: Text(
                        'Digital Certificate App v1.0.0\n© 2024 TrueCopy',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.teal[300], fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
