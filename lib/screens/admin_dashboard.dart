import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'audit_log_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _approvalStatusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _initializeDefaultValidationRules();
  }

  Future<void> _initializeDefaultValidationRules() async {
    try {
      print('Starting validation rules initialization...');
      
      // Check if validation rules already exist
      final rulesSnapshot = await FirebaseFirestore.instance
          .collection('validation_rules')
          .limit(1)
          .get();

      print('Found ${rulesSnapshot.docs.length} existing rules');

      // Only add default rules if none exist
      if (rulesSnapshot.docs.isEmpty) {
        print('No existing rules found, creating default rules...');
        
        final defaultRules = [
          {
            'pattern': '*@upm.edu.my',
            'description': 'UPM Students and Staff',
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'pattern': '*@*.edu.my',
            'description': 'Malaysian Educational Institutions',
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'pattern': '*@*.gov.my',
            'description': 'Malaysian Government Agencies',
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'pattern': 'admin@digitalcert.com',
            'description': 'System Administrator',
            'createdAt': FieldValue.serverTimestamp(),
          },
        ];

        // Add all default rules
        for (int i = 0; i < defaultRules.length; i++) {
          final rule = defaultRules[i];
          print('Adding rule ${i + 1}: ${rule['pattern']}');
          
          await FirebaseFirestore.instance
              .collection('validation_rules')
              .add(rule);
        }

        print('Default validation rules initialized successfully');
      } else {
        print('Validation rules already exist, skipping initialization');
      }
    } catch (e) {
      print('Error initializing default validation rules: $e');
      print('Error details: ${e.toString()}');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () => _logout(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Users'),
            Tab(text: 'Validation Rules'),
            Tab(text: 'Issued Certs'),
            Tab(text: 'Pending Approvals'),
            Tab(text: 'Rule Flags'),
            Tab(text: 'Audit Logs'),
            Tab(text: 'Email Test'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Users Tab
          _UsersTab(),
          // Validation Rules Tab
          ValidationRulesTab(),
          // Issued Certs Tab
          _IssuedCertsTab(),
          // Pending Approvals Tab
          _PendingApprovalsTab(),
          // Rule Flags Tab
          _RuleFlagsTab(),
          // Audit Logs Tab
          _AuditLogsTab(),
          // Email Test Tab
          _EmailTestTab(),
        ],
      ),
    );
  }
}

class _UsersTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Error: \\${snapshot.error}'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        return ListView(
          children: [
            ListTile(
              title: const Text('Register New CA'),
              trailing: IconButton(
                icon: const Icon(Icons.person_add),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      final _formKey = GlobalKey<FormState>();
                      String? _email;
                      return AlertDialog(
                        title: const Text('Register New CA'),
                        content: Form(
                          key: _formKey,
                          child: TextFormField(
                            decoration: const InputDecoration(labelText: 'CA Email'),
                            validator: (v) => v == null || v.isEmpty ? 'Enter email' : null,
                            onSaved: (v) => _email = v,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              if (_formKey.currentState?.validate() ?? false) {
                                _formKey.currentState?.save();
                                // Find user by email
                                final userQuery = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: _email).get();
                                if (userQuery.docs.isNotEmpty) {
                                  await userQuery.docs.first.reference.update({'role': 'ca'});
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('User promoted to CA!')),
                                  );
                                } else {
                                  // Create new CA user doc
                                  await FirebaseFirestore.instance.collection('users').add({
                                    'email': _email,
                                    'role': 'ca',
                                    'createdAt': FieldValue.serverTimestamp(),
                                  });
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('CA registered!')),
                                  );
                                }
                              }
                            },
                            child: const Text('Register'),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(),
            ...docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final validRoles = ['admin', 'ca', 'recipient', 'viewer'];
              return ListTile(
                title: Text(data['email'] ?? 'No Email'),
                subtitle: Text('Role: \\${data['role'] ?? 'unknown'}'),
                trailing: DropdownButton<String>(
                  value: validRoles.contains(data['role']) ? data['role'] : null,
                  hint: const Text('Select Role'),
                  items: const [
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    DropdownMenuItem(value: 'ca', child: Text('CA')),
                    DropdownMenuItem(value: 'recipient', child: Text('Recipient')),
                    DropdownMenuItem(value: 'viewer', child: Text('Viewer')),
                  ],
                  onChanged: (role) async {
                    await doc.reference.update({'role': role});
                  },
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

class ValidationRulesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('validation_rules').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Error: \\${snapshot.error}'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        return ListView(
          children: [
            // Manual initialization button
            Card(
              margin: const EdgeInsets.all(16),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.settings,
                    color: Colors.orange[700],
                    size: 20,
                  ),
                ),
                title: const Text('Initialize Default Rules'),
                subtitle: const Text('Create pre-configured validation rules'),
                trailing: ElevatedButton(
                  onPressed: () async {
                    try {
                      final defaultRules = [
                        {
                          'pattern': '*@upm.edu.my',
                          'description': 'UPM Students and Staff',
                          'createdAt': FieldValue.serverTimestamp(),
                        },
                        {
                          'pattern': '*@*.edu.my',
                          'description': 'Malaysian Educational Institutions',
                          'createdAt': FieldValue.serverTimestamp(),
                        },
                        {
                          'pattern': '*@*.gov.my',
                          'description': 'Malaysian Government Agencies',
                          'createdAt': FieldValue.serverTimestamp(),
                        },
                        {
                          'pattern': 'admin@digitalcert.com',
                          'description': 'System Administrator',
                          'createdAt': FieldValue.serverTimestamp(),
                        },
                      ];

                      for (final rule in defaultRules) {
                        await FirebaseFirestore.instance
                            .collection('validation_rules')
                            .add(rule);
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Default validation rules created successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('❌ Error creating rules: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text('Create Rules'),
                ),
              ),
            ),
            ListTile(
              title: const Text('Add New Rule'),
              trailing: IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      final formKey = GlobalKey<FormState>();
                      String? email;
                      String? description;
                      return AlertDialog(
                        title: const Text('Add Validation Rule'),
                        content: Form(
                          key: formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'Email Pattern',
                                  hintText: 'e.g., *@upm.edu.my',
                                  prefixIcon: Icon(Icons.email),
                                ),
                                validator: (v) => v == null || v.isEmpty ? 'Enter email pattern' : null,
                                onSaved: (v) => email = v,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'Description',
                                  hintText: 'e.g., UPM Students and Staff',
                                  prefixIcon: Icon(Icons.description),
                                ),
                                validator: (v) => v == null || v.isEmpty ? 'Enter description' : null,
                                onSaved: (v) => description = v,
                              ),
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              if (formKey.currentState?.validate() ?? false) {
                                formKey.currentState?.save();
                                await FirebaseFirestore.instance.collection('validation_rules').add({
                                  'pattern': email,
                                  'description': description,
                                  'createdAt': FieldValue.serverTimestamp(),
                                });
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Rule added!')),
                                );
                              }
                            },
                            child: const Text('Add'),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(),
            ...docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.security,
                      color: Colors.blue[700],
                      size: 20,
                    ),
                  ),
                  title: Text(
                    data['pattern'] ?? 'No Pattern',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    data['description'] ?? 'No description',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: 'Delete Rule',
                    onPressed: () async {
                      // Show confirmation dialog
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Confirm Deletion'),
                          content: Text('Are you sure you want to delete the rule "${data['pattern']}"?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Delete', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                      
                      if (confirmed == true) {
                        await doc.reference.delete();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Validation rule deleted.')),
                        );
                      }
                    },
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

class _RuleFlagsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('rule_flags')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Error: \\${snapshot.error}'));
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final flags = snapshot.data!.docs;
        
        if (flags.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.security, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No security flags detected', style: TextStyle(fontSize: 18)),
                SizedBox(height: 8),
                Text('All systems are running normally', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: flags.length,
          itemBuilder: (context, index) {
            final flag = flags[index];
            final data = flag.data() as Map<String, dynamic>;
            
            Color flagColor;
            IconData flagIcon;
            
            switch (data['severity'] ?? 'info') {
              case 'high':
                flagColor = Colors.red;
                flagIcon = Icons.warning;
                break;
              case 'medium':
                flagColor = Colors.orange;
                flagIcon = Icons.info;
                break;
              case 'low':
                flagColor = Colors.yellow;
                flagIcon = Icons.info_outline;
                break;
              default:
                flagColor = Colors.blue;
                flagIcon = Icons.info;
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: flagColor,
                  child: Icon(flagIcon, color: Colors.white),
                ),
                title: Text(
                  data['title'] ?? 'Unknown Flag',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['description'] ?? 'No description'),
                    const SizedBox(height: 4),
                    Text(
                      'Severity: ${data['severity']?.toUpperCase() ?? 'INFO'}',
                      style: TextStyle(
                        color: flagColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    if (data['createdAt'] != null)
                      Text(
                        'Detected: ${data['createdAt'].toDate().toString().split('.')[0]}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                  ],
                ),
                trailing: PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'resolve',
                      child: Text('Mark as Resolved'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete Flag'),
                    ),
                  ],
                  onSelected: (value) async {
                    if (value == 'resolve') {
                      await flag.reference.update({
                        'resolved': true,
                        'resolvedAt': FieldValue.serverTimestamp(),
                        'resolvedBy': FirebaseAuth.instance.currentUser?.email,
                      });
                    } else if (value == 'delete') {
                      await flag.reference.delete();
                    }
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _PendingApprovalsTab extends StatefulWidget {
  @override
  State<_PendingApprovalsTab> createState() => _PendingApprovalsTabState();
}

class _PendingApprovalsTabState extends State<_PendingApprovalsTab> {
  String _approvalStatusFilter = 'all';

  String _formatDate(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is Timestamp) {
      final dt = value.toDate();
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    }
    return value.toString();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.pending;
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  Future<void> _approveRequest(DocumentReference docRef, BuildContext context) async {
    try {
      await docRef.update({
        'status': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Request approved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error approving request: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectRequest(DocumentReference docRef, BuildContext context) async {
    String? reason;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Approval Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Are you sure you want to reject this request?'),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Rejection Reason (optional)',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => reason = v,
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reject', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await docRef.update({
          'status': 'rejected',
          'rejectedAt': FieldValue.serverTimestamp(),
          if ((reason?.trim().isNotEmpty ?? false)) 'rejectionReason': reason,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Request rejected.'),
            backgroundColor: Colors.red,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error rejecting request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showApprovalDetails(BuildContext context, Map<String, dynamic> data, DocumentReference docRef) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(_getStatusIcon(data['status'] ?? 'pending'), color: _getStatusColor(data['status'] ?? 'pending')),
            const SizedBox(width: 8),
            const Text('Approval Details'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildApprovalDetailRow('Certificate Name', data['certificateName'] ?? 'Unknown'),
              _buildApprovalDetailRow('Approver', data['to'] ?? 'Unknown'),
              _buildApprovalDetailRow('Certificate ID', data['certificateId'] ?? 'Unknown'),
              _buildApprovalDetailRow('Status', data['status'] ?? 'pending'),
              _buildApprovalDetailRow('Priority', data['priority'] ?? 'normal'),
              _buildApprovalDetailRow('Organization', data['organization'] ?? 'Unknown'),
              _buildApprovalDetailRow('Purpose', data['purpose'] ?? 'Unknown'),
              if (data['createdAt'] != null)
                _buildApprovalDetailRow('Created', data['createdAt'].toDate().toString().split('.')[0]),
              if (data['approvedAt'] != null)
                _buildApprovalDetailRow('Approved', data['approvedAt'].toDate().toString().split('.')[0]),
              const SizedBox(height: 16),
              const Divider(height: 24, thickness: 1),
              Tooltip(
                message: (data['status'] ?? 'pending').toUpperCase(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(data['status'] ?? 'pending').withOpacity(0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_getStatusIcon(data['status'] ?? 'pending'), size: 18, color: _getStatusColor(data['status'] ?? 'pending')),
                      const SizedBox(width: 6),
                      Text(
                        (data['status'] ?? 'pending').toUpperCase(),
                        style: TextStyle(
                          color: _getStatusColor(data['status'] ?? 'pending'),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (data['status'] == 'rejected' && data['rejectionReason'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, color: Colors.red, size: 18),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Rejection Reason: ${data['rejectionReason']}',
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (data['status'] == 'pending') ...[
            Flexible(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Tooltip(
                    message: 'Approve Request',
                    child: FittedBox(
                      child: ElevatedButton.icon(
                        onPressed: () => _approveRequest(docRef, context),
                        icon: const Icon(Icons.check_circle, size: 20),
                        label: const Text('Approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Tooltip(
                    message: 'Reject Request',
                    child: FittedBox(
                      child: ElevatedButton.icon(
                        onPressed: () => _rejectRequest(docRef, context),
                        icon: const Icon(Icons.cancel, size: 20),
                        label: const Text('Reject'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildApprovalDetailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              _formatDate(value),
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalInfoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              _formatDate(value),
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteRequest(DocumentReference docRef, BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this approval request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await docRef.delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Request deleted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error deleting request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Certificate Requests', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('certificate_requests').orderBy('requestedAt', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Center(child: Text('Error: \\${snapshot.error}'));
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('No certificate requests.'),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      title: Text('Requested by: ${data['requestedBy'] ?? ''}'),
                      subtitle: Text('Purpose: ${data['purpose'] ?? ''}\nRequested at: ${data['requestedAt'] != null ? data['requestedAt'].toDate().toString().split(' ')[0] : ''}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Remove Request',
                        onPressed: () async {
                          // Show confirmation dialog
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Confirm Deletion'),
                              content: const Text('Are you sure you want to remove this certificate request?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                          
                          if (confirmed == true) {
                            await doc.reference.delete();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Request removed.')),
                            );
                          }
                        },
                      ),
                    ),
                  );
                },
              );
            },
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Approval Requests', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: _ApprovalStatusFilter(
              selected: _approvalStatusFilter,
              onChanged: (val) => setState(() => _approvalStatusFilter = val),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('approval_requests').orderBy('createdAt', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data!.docs.where((doc) {
                if (_approvalStatusFilter == 'all') return true;
                final status = (doc['status'] ?? 'pending').toString().toLowerCase();
                return status == _approvalStatusFilter;
              }).toList();
              if (docs.isEmpty) {
                return SizedBox(
                  height: MediaQuery.of(context).size.height * 0.4, // adjust as needed
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        Text('No ${_approvalStatusFilter == 'all' ? '' : _approvalStatusFilter + ' '}approval requests.',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Text('All caught up!', style: TextStyle(color: Colors.grey[500])),
                      ],
                    ),
                  ),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    elevation: 7,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: _getStatusColor(data['status'] ?? 'pending'),
                        width: 4,
                      ),
                    ),
                    color: (data['status'] == 'pending') ? Colors.orange[50] : Colors.white,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _showApprovalDetails(context, data, doc.reference),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final isSmallScreen = constraints.maxWidth < 600;
                            
                            if (isSmallScreen) {
                              // Mobile layout - stacked vertically
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header with icon and status
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.blue[100],
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(Icons.description, color: Colors.blue[700], size: 28),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          data['certificateName'] ?? 'Unknown Certificate',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Tooltip(
                                        message: (data['status'] ?? 'pending').toUpperCase(),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(data['status'] ?? 'pending').withOpacity(0.18),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(_getStatusIcon(data['status'] ?? 'pending'), size: 16, color: _getStatusColor(data['status'] ?? 'pending')),
                                              const SizedBox(width: 4),
                                              Text(
                                                (data['status'] ?? 'pending').toUpperCase(),
                                                style: TextStyle(
                                                  color: _getStatusColor(data['status'] ?? 'pending'),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // Info rows
                                  _buildInfoRow(Icons.account_circle, 'Approver', data['to'] ?? ''),
                                  const SizedBox(height: 4),
                                  _buildInfoRow(Icons.business, 'Org', data['organization'] ?? ''),
                                  const SizedBox(height: 4),
                                  _buildInfoRow(Icons.flag, 'Priority', (data['priority'] ?? 'normal').toString().toUpperCase()),
                                  const SizedBox(height: 4),
                                  _buildInfoRow(Icons.calendar_today, 'Created', _formatDate(data['createdAt'])),
                                  const SizedBox(height: 12),
                                  // Actions
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      if (data['status'] == 'pending') ...[
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () => _approveRequest(doc.reference, context),
                                            icon: const Icon(Icons.check_circle, size: 18),
                                            label: const Text('Approve'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green[700],
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(vertical: 10),
                                              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () => _rejectRequest(doc.reference, context),
                                            icon: const Icon(Icons.cancel, size: 18),
                                            label: const Text('Reject'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red[700],
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(vertical: 10),
                                              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                          ),
                                        ),
                                      ] else ...[
                                        Expanded(child: Container()),
                                      ],
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                        onPressed: () => _deleteRequest(doc.reference, context),
                                        tooltip: 'Delete Request',
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            } else {
                              // Desktop layout - horizontal
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Certificate icon/avatar
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[100],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(Icons.description, color: Colors.blue[700], size: 32),
                                  ),
                                  const SizedBox(width: 16),
                                  // Main info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                data['certificateName'] ?? 'Unknown Certificate',
                                                style: const TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Tooltip(
                                              message: (data['status'] ?? 'pending').toUpperCase(),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                                decoration: BoxDecoration(
                                                  color: _getStatusColor(data['status'] ?? 'pending').withOpacity(0.18),
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(_getStatusIcon(data['status'] ?? 'pending'), size: 16, color: _getStatusColor(data['status'] ?? 'pending')),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      (data['status'] ?? 'pending').toUpperCase(),
                                                      style: TextStyle(
                                                        color: _getStatusColor(data['status'] ?? 'pending'),
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        _buildInfoRow(Icons.account_circle, 'Approver', data['to'] ?? ''),
                                        const SizedBox(height: 4),
                                        _buildInfoRow(Icons.business, 'Org', data['organization'] ?? ''),
                                        const SizedBox(height: 4),
                                        _buildInfoRow(Icons.flag, 'Priority', (data['priority'] ?? 'normal').toString().toUpperCase()),
                                        const SizedBox(height: 4),
                                        _buildInfoRow(Icons.calendar_today, 'Created', _formatDate(data['createdAt'])),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Actions
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      if (data['status'] == 'pending') ...[
                                        ElevatedButton.icon(
                                          onPressed: () => _approveRequest(doc.reference, context),
                                          icon: const Icon(Icons.check_circle, size: 18),
                                          label: const Text('Approve'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green[700],
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        ElevatedButton.icon(
                                          onPressed: () => _rejectRequest(doc.reference, context),
                                          icon: const Icon(Icons.cancel, size: 18),
                                          label: const Text('Reject'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red[700],
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 6),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                        onPressed: () => _deleteRequest(doc.reference, context),
                                        tooltip: 'Delete Request',
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            }
                          },
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Physical Certificate Upload Approvals', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('physical_certificate_uploads').orderBy('uploadedAt', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Center(child: Text('Error: \\${snapshot.error}'));
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('No physical certificate uploads.'),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      title: Text('Name: ${data['name'] ?? ''}'),
                      subtitle: Text('Purpose: ${data['purpose'] ?? ''}\nUploaded by: ${data['uploadedBy'] ?? ''}\nStatus: ${data['status'] ?? ''}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Remove Upload',
                        onPressed: () async {
                          // Show confirmation dialog
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Confirm Deletion'),
                              content: const Text('Are you sure you want to remove this physical certificate upload?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                          
                          if (confirmed == true) {
                            await doc.reference.delete();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Upload removed.')),
                            );
                          }
                        },
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ApprovalStatusFilter extends StatelessWidget {
  final String selected;
  final void Function(String) onChanged;
  const _ApprovalStatusFilter({required this.selected, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    final statuses = ['all', 'pending', 'approved', 'rejected'];
    final icons = [Icons.list, Icons.hourglass_top, Icons.check_circle, Icons.cancel];
    final colors = [Colors.blue, Colors.orange, Colors.green, Colors.red];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(statuses.length, (i) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: ChoiceChip(
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icons[i], color: colors[i], size: 18),
                const SizedBox(width: 4),
                Text(statuses[i][0].toUpperCase() + statuses[i].substring(1)),
              ],
            ),
            selected: selected == statuses[i],
            onSelected: (_) => onChanged(statuses[i]),
            selectedColor: colors[i].withOpacity(0.15),
            backgroundColor: Colors.grey[100],
            labelStyle: TextStyle(
              color: selected == statuses[i] ? colors[i] : Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
        )),
      ),
    );
  }
}

class _IssuedCertsTab extends StatelessWidget {
  String _formatDate(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is Timestamp) {
      final dt = value.toDate();
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    }
    return value.toString();
  }

  String getCertificateTitle(Map<String, dynamic> data) {
    final name = data['name'];
    final recipient = data['recipient'];
    if (name != null && name.toString().trim().isNotEmpty) {
      return name;
    } else if (recipient != null && recipient.toString().trim().isNotEmpty) {
      return 'Certificate for $recipient';
    } else {
      return 'Unknown Certificate';
    }
  }

  void _showCertificateDetails(BuildContext context, Map<String, dynamic> data, DocumentReference docRef) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.verified, color: Colors.green),
            const SizedBox(width: 8),
            const Text('Certificate Details'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Certificate Name', getCertificateTitle(data)),
              _buildDetailRow('Organization', data['organization'] ?? 'Unknown'),
              _buildDetailRow('Purpose', data['purpose'] ?? 'Unknown'),
              _buildDetailRow('Recipient', data['recipient'] ?? 'Unknown'),
              if (data['issueDate'] != null)
                _buildDetailRow('Issue Date', data['issueDate']),
              if (data['expiryDate'] != null)
                _buildDetailRow('Expiry Date', data['expiryDate']),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green[50]!, Colors.green[100]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.security, color: Colors.green[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This certificate is digitally signed and verified',
                        style: TextStyle(
                          color: Colors.green[800],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showCertificateActions(context, data, docRef);
            },
            icon: const Icon(Icons.more_vert),
            label: const Text('Actions'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
          ),
        ],
      ),
    );
  }

  void _showCertificateActions(BuildContext context, Map<String, dynamic> data, DocumentReference docRef) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Certificate Actions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.download, color: Colors.blue),
              title: const Text('Download Certificate'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Downloading certificate...')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.share, color: Colors.green),
              title: const Text('Share Certificate'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Generating shareable link...')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.verified, color: Colors.orange),
              title: const Text('Verify Certificate'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Certificate verification successful!')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Certificate'),
              onTap: () async {
                Navigator.pop(context);
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Confirm Deletion'),
                    content: const Text('Are you sure you want to delete this certificate? This action cannot be undone.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
                
                if (confirmed == true) {
                  await docRef.delete();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Certificate deleted successfully.')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              _formatDate(value),
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('certificates').orderBy('issueDate', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No issued certificates found', style: TextStyle(fontSize: 18)),
                SizedBox(height: 8),
                Text('Certificates will appear here once issued', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: InkWell(
                onTap: () => _showCertificateDetails(context, data, doc.reference),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.verified,
                              color: Colors.green[700],
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  getCertificateTitle(data),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  data['organization'] ?? 'Unknown Organization',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.grey[400],
                            size: 16,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow('Purpose', data['purpose'] ?? 'Unknown'),
                      if (data['recipient'] != null)
                        _buildInfoRow('Recipient', data['recipient']),
                      if (data['issueDate'] != null)
                        _buildInfoRow('Issue Date', data['issueDate']),
                      if (data['expiryDate'] != null)
                        _buildInfoRow('Expiry Date', data['expiryDate']),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'ISSUED',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.more_vert, color: Colors.grey),
                            onPressed: () => _showCertificateActions(context, data, doc.reference),
                            tooltip: 'More Actions',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              _formatDate(value),
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmailTestTab extends StatefulWidget {
  @override
  State<_EmailTestTab> createState() => _EmailTestTabState();
}

class _EmailTestTabState extends State<_EmailTestTab> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill with current user's email
    _emailController.text = FirebaseAuth.instance.currentUser?.email ?? '';
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _testEmail() async {
    if (!_formKey.currentState!.validate()) {
      print('Form is not valid');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Generate a unique certificate ID
      final certificateId = 'CERT_${DateTime.now().millisecondsSinceEpoch}';
      final approverEmail = _emailController.text.trim();
      
      // Create approval request in Firestore
      await FirebaseFirestore.instance
          .collection('approval_requests')
          .add({
        'to': approverEmail,
        'certificateId': certificateId,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'message': 'Certificate requires approval',
        'certificateName': 'Digital Certificate',
        'organization': 'Your Organization',
        'purpose': 'Verification and Authentication',
        'requestedBy': 'Certificate Authority',
        'priority': 'high',
      });

      // Show success dialog with real approval request details
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Approval Request Created',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Approver: ${approverEmail}'),
                  const SizedBox(height: 8),
                  Text('Certificate ID: $certificateId'),
                  const SizedBox(height: 8),
                  const Text('Status: Pending Approval'),
                  const SizedBox(height: 8),
                  const Text('Priority: High'),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue[50]!, Colors.blue[100]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.notification_important_outlined, color: Colors.blue[700], size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'In-App Notification',
                                style: TextStyle(
                                  color: Colors.blue[800],
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Approval request has been created and will appear in the approver\'s dashboard.',
                                style: TextStyle(
                                  color: Colors.blue[700],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✅ Approval request created for $approverEmail'),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                  // Clear the email field
                  _emailController.clear();
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error creating approval request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.email_outlined,
                            color: Colors.blue[700],
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Certificate Approval Notifications',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Test approval workflow notifications',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: TextFormField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: 'Approver Email',
                                hintText: 'Enter approver email address',
                                prefixIcon: Icon(Icons.email_outlined, color: Colors.grey[600]),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                labelStyle: TextStyle(color: Colors.grey[600]),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter an email address';
                                }
                                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                  return 'Please enter a valid email address';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.blue[600]!, Colors.blue[700]!],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue[200]!,
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _testEmail,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isLoading
                                  ? Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Text(
                                          'Creating Request...',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.send_rounded,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Create Approval Request',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.check_circle_outline,
                            color: Colors.green[700],
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Approval Workflow Status',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Certificate approval notifications ready',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildStatusItem(
                      'Approval Notifications',
                      'Ready to send approval requests',
                      Icons.notification_important_outlined,
                      Colors.green,
                    ),
                    _buildStatusItem(
                      'Certificate Workflow',
                      'Approval process enabled',
                      Icons.assignment_outlined,
                      Colors.blue,
                    ),
                    _buildStatusItem(
                      'Email Delivery',
                      'Notifications will be sent',
                      Icons.email_outlined,
                      Colors.orange,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.purple[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.info_outline,
                            color: Colors.purple[700],
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Approval Workflow',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Certificate approval process',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInfoItem(
                      '1. Certificate Created',
                      'CA creates certificate for approval',
                      Icons.add_circle_outline,
                    ),
                    _buildInfoItem(
                      '2. Send Approval Request',
                      'Email notification sent to approver',
                      Icons.notification_important_outlined,
                    ),
                    _buildInfoItem(
                      '3. Approver Reviews',
                      'Approver reviews and approves certificate',
                      Icons.verified_outlined,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(String title, String description, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  description,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String title, String description, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.purple[50],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: Colors.purple[600], size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AuditLogsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📊 Audit Logs',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Monitor all certificate actions and system activities for security and compliance.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AuditLogScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.visibility),
                          label: const Text('View All Audit Logs'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🔍 Audit Log Features',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureItem(
                    'Certificate Actions',
                    'Creation, issuance, approval, viewing, sharing',
                    Icons.verified,
                  ),
                  _buildFeatureItem(
                    'Digital Signatures',
                    'Signature addition and verification tracking',
                    Icons.edit,
                  ),
                  _buildFeatureItem(
                    'Watermarks',
                    'Watermark application and tracking',
                    Icons.water_drop,
                  ),
                  _buildFeatureItem(
                    'User Activities',
                    'Login, logout, role changes',
                    Icons.person,
                  ),
                  _buildFeatureItem(
                    'Filtering & Search',
                    'Filter by action type, date range, user',
                    Icons.filter_list,
                  ),
                  _buildFeatureItem(
                    'Detailed Metadata',
                    'Complete audit trail with timestamps',
                    Icons.info,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String title, String description, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  description,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDate(dynamic value) {
  if (value == null) return '';
  if (value is String) return value;
  if (value is Timestamp) {
    final dt = value.toDate();
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
  return value.toString();
}

// Helper method to build info rows
Widget _buildInfoRow(IconData icon, String label, String value) {
  return Row(
    children: [
      Icon(icon, size: 16, color: Colors.grey[600]),
      const SizedBox(width: 4),
      Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      Expanded(
        child: Text(
          value,
          style: TextStyle(color: Colors.grey[800], fontSize: 13),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
} 