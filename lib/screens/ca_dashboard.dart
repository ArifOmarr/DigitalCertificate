import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CaDashboard extends StatelessWidget {
  const CaDashboard({super.key});

  Future<String?> _getRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
    return doc.data()?['role'] as String?;
  }

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  void _goToCreateCertificate(BuildContext context) {
    Navigator.pushNamed(context, '/ca_dashboard/create_certificate');
  }

  void _goToCertifyTrueCopies(BuildContext context) {
    Navigator.pushNamed(context, '/ca_approvals');
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

  void _showClientProfiles(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: SizedBox(
              width: 400,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.business, color: Colors.teal),
                        const SizedBox(width: 8),
                        const Text(
                          'Client Profiles',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(),
                    SizedBox(
                      height: 350,
                      width: 350,
                      child: StreamBuilder<QuerySnapshot>(
                        stream:
                            FirebaseFirestore.instance
                                .collection('clients')
                                .orderBy('name')
                                .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          final docs = snapshot.data!.docs;
                          return ListView.builder(
                            itemCount: docs.length + 1,
                            itemBuilder: (context, index) {
                              if (index == docs.length) {
                                // Add new client button
                                return ListTile(
                                  leading: const Icon(
                                    Icons.add,
                                    color: Colors.teal,
                                  ),
                                  title: const Text('Add New Client'),
                                  onTap: () async {
                                    final nameController =
                                        TextEditingController();
                                    final orgController =
                                        TextEditingController();
                                    await showDialog(
                                      context: context,
                                      builder:
                                          (context) => AlertDialog(
                                            title: const Text('Add Client'),
                                            content: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                TextField(
                                                  controller: nameController,
                                                  decoration:
                                                      const InputDecoration(
                                                        labelText:
                                                            'Client Name',
                                                      ),
                                                ),
                                                TextField(
                                                  controller: orgController,
                                                  decoration:
                                                      const InputDecoration(
                                                        labelText:
                                                            'Organization/Type',
                                                      ),
                                                ),
                                              ],
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed:
                                                    () =>
                                                        Navigator.pop(context),
                                                child: const Text('Cancel'),
                                              ),
                                              ElevatedButton(
                                                onPressed: () async {
                                                  if (nameController
                                                      .text
                                                      .isNotEmpty) {
                                                    await FirebaseFirestore
                                                        .instance
                                                        .collection('clients')
                                                        .add({
                                                          'name':
                                                              nameController
                                                                  .text,
                                                          'organization':
                                                              orgController
                                                                  .text,
                                                          'createdAt':
                                                              FieldValue.serverTimestamp(),
                                                        });
                                                    Navigator.pop(context);
                                                  }
                                                },
                                                child: const Text('Add'),
                                              ),
                                            ],
                                          ),
                                    );
                                  },
                                );
                              }
                              final doc = docs[index];
                              final data = doc.data() as Map<String, dynamic>;
                              return ListTile(
                                leading: const Icon(
                                  Icons.business,
                                  color: Colors.teal,
                                ),
                                title: Text(data['name'] ?? ''),
                                subtitle: Text(data['organization'] ?? ''),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Colors.orange,
                                      ),
                                      onPressed: () async {
                                        final nameController =
                                            TextEditingController(
                                              text: data['name'],
                                            );
                                        final orgController =
                                            TextEditingController(
                                              text: data['organization'],
                                            );
                                        await showDialog(
                                          context: context,
                                          builder:
                                              (context) => AlertDialog(
                                                title: const Text(
                                                  'Edit Client',
                                                ),
                                                content: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    TextField(
                                                      controller:
                                                          nameController,
                                                      decoration:
                                                          const InputDecoration(
                                                            labelText:
                                                                'Client Name',
                                                          ),
                                                    ),
                                                    TextField(
                                                      controller: orgController,
                                                      decoration:
                                                          const InputDecoration(
                                                            labelText:
                                                                'Organization/Type',
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed:
                                                        () => Navigator.pop(
                                                          context,
                                                        ),
                                                    child: const Text('Cancel'),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () async {
                                                      if (nameController
                                                          .text
                                                          .isNotEmpty) {
                                                        await doc.reference
                                                            .update({
                                                              'name':
                                                                  nameController
                                                                      .text,
                                                              'organization':
                                                                  orgController
                                                                      .text,
                                                            });
                                                        Navigator.pop(context);
                                                      }
                                                    },
                                                    child: const Text('Save'),
                                                  ),
                                                ],
                                              ),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () async {
                                        final confirm = await showDialog(
                                          context: context,
                                          builder:
                                              (context) => AlertDialog(
                                                title: const Text(
                                                  'Delete Client',
                                                ),
                                                content: const Text(
                                                  'Are you sure you want to delete this client?',
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed:
                                                        () => Navigator.pop(
                                                          context,
                                                          false,
                                                        ),
                                                    child: const Text('Cancel'),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed:
                                                        () => Navigator.pop(
                                                          context,
                                                          true,
                                                        ),
                                                    child: const Text('Delete'),
                                                  ),
                                                ],
                                              ),
                                        );
                                        if (confirm == true) {
                                          await doc.reference.delete();
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: Colors.teal[50],
      appBar: AppBar(
        title: const Text('CA Dashboard'),
        backgroundColor: Colors.teal,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
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
                          backgroundColor: const Color.fromARGB(255, 224, 12, 12),
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
                          backgroundColor: const Color.fromARGB(255, 224, 12, 12),
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
      body: FutureBuilder<String?>(
        future: _getRole(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data != 'ca') {
            return const Center(child: Text('Access denied.'));
          }
          final sectionHeaderStyle = TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.teal[800],
          );
          return SingleChildScrollView(
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
                    padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.verified, color: Colors.teal, size: 36),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome, CA!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                user?.email ?? '',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Modern Action Cards Grid
                Text(
                  'Actions',
                  style: sectionHeaderStyle,
                ),
                const SizedBox(height: 18),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 24,
                  runSpacing: 24,
                  children: [
                    _ModernActionCard(
                      icon: Icons.add,
                      label: 'Create/Issue Certificate',
                      color: Colors.teal,
                      onTap: () => _goToCreateCertificate(context),
                    ),
                    _ModernActionCard(
                      icon: Icons.verified,
                      label: 'Certify True Copies',
                      color: Colors.orange,
                      onTap: () => _goToCertifyTrueCopies(context),
                    ),
                    _ModernActionCard(
                      icon: Icons.list_alt,
                      label: 'View Certificate Requests',
                      color: Colors.blue,
                      onTap: () => _showCertificateRequests(context),
                    ),
                    _ModernActionCard(
                      icon: Icons.business,
                      label: 'Manage Client Profiles',
                      color: Colors.deepPurple,
                      onTap: () => _showClientProfiles(context),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                // Issued Certificates Section
                Text(
                  'Issued Certificates',
                  style: sectionHeaderStyle,
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('certificates')
                          //.where('issuerId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                          //.orderBy('issueDate', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        final certs = snapshot.data!.docs;
                        if (certs.isEmpty) {
                          return const Text(
                            'No certificates issued yet.',
                          );
                        }
                        return Column(
                          children: List.generate(certs.length, (index) {
                            final doc = certs[index];
                            final data = doc.data() as Map<String, dynamic>;
                            final revoked = data['revoked'] == true;
                            final title = data['title'] ?? 'Untitled';
                            final recipient = data['recipientEmail'] ?? 'Unknown';
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                                leading: CircleAvatar(
                                  backgroundColor: Colors.teal[100],
                                  child: Icon(Icons.description, color: Colors.teal[700]),
                                ),
                                title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Recipient: $recipient'),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Chip(
                                          label: Text(revoked ? 'Revoked' : 'Active'),
                                          backgroundColor: revoked ? Colors.red[50] : Colors.green[50],
                                          labelStyle: TextStyle(
                                            color: revoked ? Colors.red[700] : Colors.green[700],
                                            fontWeight: FontWeight.bold,
                                          ),
                                          visualDensity: VisualDensity.compact,
                                          padding: const EdgeInsets.symmetric(horizontal: 8),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.share,
                                    color: Colors.teal,
                                  ),
                                  tooltip: 'Share Certificate',
                                  onPressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/share_certificate',
                                      arguments: {
                                        'certificateId': doc.id,
                                      },
                                    );
                                  },
                                ),
                              ),
                            );
                          }),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ModernActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ModernActionCard({
    Key? key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  }) : super(key: key);

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
              color: color.withOpacity(0.10),
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
          crossAxisAlignment: CrossAxisAlignment.center,
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
                height: 1.2,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
