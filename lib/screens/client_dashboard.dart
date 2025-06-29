import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ClientDashboard extends StatelessWidget {
  const ClientDashboard({super.key});

  void _showRequestDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final _formKey = GlobalKey<FormState>();
        String? _purpose;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Request New Certificate'),
          content: Form(
            key: _formKey,
            child: TextFormField(
              decoration: const InputDecoration(labelText: 'Purpose/Reason'),
              validator: (v) => v == null || v.isEmpty ? 'Enter purpose' : null,
              onSaved: (v) => _purpose = v,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                if (_formKey.currentState?.validate() ?? false) {
                  _formKey.currentState?.save();
                  final user = FirebaseAuth.instance.currentUser;
                  await FirebaseFirestore.instance
                      .collection('certificate_requests')
                      .add({
                        'requestedBy': user?.email,
                        'purpose': _purpose,
                        'requestedAt': FieldValue.serverTimestamp(),
                      });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Request submitted!')),
                  );
                }
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  void _showCertificateRequests(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          builder: (context, scrollController) {
            return StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('certificate_requests')
                      .orderBy('requestedAt', descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(child: Text('No certificate requests.'));
                }
                return ListView.builder(
                  controller: scrollController,
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final status = data['status'] ?? 'Pending';
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        title: Text(
                          'Requested by: ${data['requestedBy'] ?? ''}',
                        ),
                        subtitle: Text(
                          'Purpose: ${data['purpose'] ?? ''}\nRequested at: ${data['requestedAt'] != null ? data['requestedAt'].toDate().toString().split(' ')[0] : ''}\nStatus: $status',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (status != 'Complete')
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () async {
                                  await doc.reference.update({
                                    'status': 'Complete',
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Marked as complete.'),
                                    ),
                                  );
                                },
                                child: const Text('Mark Complete'),
                              ),
                            if (status == 'Complete')
                              const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  void _goToDonation(BuildContext context) {
    Navigator.pushNamed(context, '/donation');
  }

  void _goToDonationHistory(BuildContext context) {
    Navigator.pushNamed(context, '/donation_history');
  }

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.teal[50],
      appBar: AppBar(
        title: const Text('Client Dashboard'),
        backgroundColor: Colors.teal,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            final shouldLogout = await showDialog<bool>(
              context: context,
              builder:
                  (context) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: const Text('Log Out?'),
                    content: const Text(
                      'Do you want to log out and exit the dashboard?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('No, Stay'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Yes, Log Out'),
                      ),
                    ],
                  ),
            );
            if (shouldLogout == true) {
              await FirebaseAuth.instance.signOut();
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/', (route) => false);
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () {
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            Navigator.of(context).pop(); // Close dialog
                            _logout(context); // Logout
                          },
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              color: Colors.teal[400],
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 28,
                  horizontal: 24,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, color: Colors.teal, size: 36),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Welcome, Client!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            user?.email ?? '',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Action Buttons
            Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal[800],
                  ),
                ),
                const SizedBox(height: 16),
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: _ActionCard(
                        icon: Icons.folder,
                        label: 'Request Certificate Issuance',
                        color: Colors.teal,
                        onTap: () => _showRequestDialog(context),
                      ),
                    ),
                    
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: _ActionCard(
                        icon: Icons.upload_file,
                        label: 'View Certificate Requests',
                        color: Colors.blue,
                        onTap: () => _showCertificateRequests(context),
                      ),
                    ),
                    
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                      width: double.infinity,
                      child: _ActionCard(
                        icon: Icons.history,
                        label: 'Donation History',
                        color: Colors.deepPurple,
                        onTap: () => _goToDonationHistory(context),
                      ),
                    ),
                const SizedBox(height: 14),
                SizedBox(
                      width: double.infinity,
                      child: _ActionCard(
                        icon: Icons.favorite,
                        label: 'Donate',
                        color: Colors.pink,
                        onTap: () => _goToDonation(context),
                      ),
                    ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 180,
        height: 140,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: color.withOpacity(0.18), width: 2),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 16),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
