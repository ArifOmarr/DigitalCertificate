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
                          backgroundColor: Colors.teal,
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
            onPressed: () => _logout(context),
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
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.teal[200],
                      child: Icon(Icons.verified, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Welcome, ${user?.email ?? ''}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Center(
                  child: Column(
                    children: [
                      Text(
                        'Certificate Management',
                        style: sectionHeaderStyle,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 32,
                        runSpacing: 32,
                        children: [
                          _DashboardActionCard(
                            icon: Icons.add,
                            label: 'Create/Issue Certificate',
                            onTap: () => _goToCreateCertificate(context),
                          ),
                          _DashboardActionCard(
                            icon: Icons.verified,
                            label: 'Certify True Copies',
                            onTap: () => _goToCertifyTrueCopies(context),
                          ),
                          _DashboardActionCard(
                            icon: Icons.list_alt,
                            label: 'View Certificate Requests',
                            onTap: () => _showCertificateRequests(context),
                          ),
                          _DashboardActionCard(
                            icon: Icons.business,
                            label: 'Manage Client Profiles',
                            onTap: () => _showClientProfiles(context),
                          ),
                        ],
                      ),
                    ],
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

class _DashboardActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DashboardActionCard({
    Key? key,
    required this.icon,
    required this.label,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 220,
        height: 180,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.teal.withOpacity(0.10),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(color: Colors.teal[100]!, width: 2),
        ),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 18),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: Colors.teal[700]),
            const SizedBox(height: 18),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                height: 1.2,
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
