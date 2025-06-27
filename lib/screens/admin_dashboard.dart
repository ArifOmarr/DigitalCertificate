import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
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
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
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
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Users'),
            Tab(text: 'Validation Rules'),
            Tab(text: 'Issued Certs'),
            Tab(text: 'Pending Approvals'),
            Tab(text: 'Rule Flags'),
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
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
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
                            decoration: const InputDecoration(
                              labelText: 'CA Email',
                            ),
                            validator:
                                (v) =>
                                    v == null || v.isEmpty
                                        ? 'Enter email'
                                        : null,
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
                                final userQuery =
                                    await FirebaseFirestore.instance
                                        .collection('users')
                                        .where('email', isEqualTo: _email)
                                        .get();
                                if (userQuery.docs.isNotEmpty) {
                                  await userQuery.docs.first.reference.update({
                                    'role': 'ca',
                                  });
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('User promoted to CA!'),
                                    ),
                                  );
                                } else {
                                  // Create new CA user doc
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .add({
                                        'email': _email,
                                        'role': 'ca',
                                        'createdAt':
                                            FieldValue.serverTimestamp(),
                                      });
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('CA registered!'),
                                    ),
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
              final currentRole =
                  validRoles.contains(data['role']) ? data['role'] : 'admin';
              Color roleColor;
              switch (currentRole) {
                case 'admin':
                  roleColor = Colors.teal;
                  break;
                case 'ca':
                  roleColor = Colors.blue;
                  break;
                case 'recipient':
                  roleColor = Colors.green;
                  break;
                case 'viewer':
                  roleColor = Colors.orange;
                  break;
                default:
                  roleColor = Colors.grey;
              }
              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 20,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(Icons.email, color: Colors.teal[400]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['email'] ?? 'No Email',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.verified_user,
                                  color: roleColor,
                                  size: 18,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  currentRole[0].toUpperCase() +
                                      currentRole.substring(1),
                                  style: TextStyle(
                                    color: roleColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      DropdownButton<String>(
                        value: currentRole,
                        items: const [
                          DropdownMenuItem(
                            value: 'admin',
                            child: Text('Admin'),
                          ),
                          DropdownMenuItem(value: 'ca', child: Text('CA')),
                          DropdownMenuItem(
                            value: 'recipient',
                            child: Text('Recipient'),
                          ),
                          DropdownMenuItem(
                            value: 'viewer',
                            child: Text('Viewer'),
                          ),
                        ],
                        onChanged: (role) async {
                          await doc.reference.update({'role': role});
                        },
                        dropdownColor: Colors.white,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        iconEnabledColor: roleColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }
}

class _DashboardActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _DashboardActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 220,
          height: 120,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.teal),
              const SizedBox(height: 16),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ValidationRulesTab extends StatefulWidget {
  @override
  State<ValidationRulesTab> createState() => _ValidationRulesTabState();
}

class _ValidationRulesTabState extends State<ValidationRulesTab> {
  final _formKey = GlobalKey<FormState>();
  Map<String, bool> _requiredFields = {};
  Map<String, String> _fieldValidations = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadValidationRules();
  }

  Future<void> _loadValidationRules() async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('validation_rules')
              .doc('default')
              .get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _requiredFields = Map<String, bool>.from(
            data['requiredFields'] ?? {},
          );
          _fieldValidations = Map<String, String>.from(
            data['fieldValidations'] ?? {},
          );
          _isLoading = false;
        });
      } else {
        // Set default values
        setState(() {
          _requiredFields = {
            'name': true,
            'organization': true,
            'purpose': true,
            'issueDate': true,
            'expiryDate': false,
          };
          _fieldValidations = {
            'name': 'min:2,max:100',
            'organization': 'min:2,max:100',
            'purpose': 'min:5,max:500',
            'issueDate': 'future_date_allowed:false',
            'expiryDate': 'future_date_required:true',
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveValidationRules() async {
    try {
      await FirebaseFirestore.instance
          .collection('validation_rules')
          .doc('default')
          .set({
            'requiredFields': _requiredFields,
            'fieldValidations': _fieldValidations,
            'updatedAt': FieldValue.serverTimestamp(),
            'updatedBy': FirebaseAuth.instance.currentUser?.email ?? 'admin',
          });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Validation rules saved successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving rules: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Required Fields Configuration',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._requiredFields.entries.map(
                      (entry) => CheckboxListTile(
                        title: Text(entry.key),
                        subtitle: Text('Certificate must have this field'),
                        value: entry.value,
                        onChanged: (value) {
                          setState(() {
                            _requiredFields[entry.key] = value ?? false;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Field Validation Rules',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._fieldValidations.entries.map(
                      (entry) => ListTile(
                        title: Text(entry.key),
                        subtitle: Text(entry.value),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed:
                              () => _editValidationRule(entry.key, entry.value),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveValidationRules,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Save Validation Rules',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editValidationRule(String field, String currentRule) {
    final controller = TextEditingController(text: currentRule);
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Edit Validation Rule for $field'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Validation Rule',
                hintText: 'e.g., min:2,max:100',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _fieldValidations[field] = controller.text;
                  });
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }
}

class _RuleFlagsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('rule_flags')
              .orderBy('createdAt', descending: true)
              .limit(50)
              .snapshots(),
      builder: (context, snapshot) {
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
                Text(
                  'No security flags detected',
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 8),
                Text(
                  'All systems are running normally',
                  style: TextStyle(color: Colors.grey),
                ),
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
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
                trailing: PopupMenuButton(
                  itemBuilder:
                      (context) => [
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

class _PendingApprovalsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Certificate Requests',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('certificate_requests')
                    .orderBy('requestedAt', descending: true)
                    .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());
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
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      title: Text('Requested by: ${data['requestedBy'] ?? ''}'),
                      subtitle: Text(
                        'Purpose: ${data['purpose'] ?? ''}\nRequested at: ${data['requestedAt'] != null ? data['requestedAt'].toDate().toString().split(' ')[0] : ''}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Remove Request',
                        onPressed: () async {
                          // Show confirmation dialog
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  title: const Text('Confirm Deletion'),
                                  content: const Text(
                                    'Are you sure you want to remove this certificate request?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed:
                                          () =>
                                              Navigator.of(context).pop(false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed:
                                          () => Navigator.of(context).pop(true),
                                      child: const Text(
                                        'Delete',
                                        style: TextStyle(color: Colors.red),
                                      ),
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
            child: Text(
              'Physical Certificate Upload Approvals',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('physical_certificate_uploads')
                    .orderBy('uploadedAt', descending: true)
                    .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());
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
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      title: Text('Name: ${data['name'] ?? ''}'),
                      subtitle: Text(
                        'Purpose: ${data['purpose'] ?? ''}\nUploaded by: ${data['uploadedBy'] ?? ''}\nStatus: ${data['status'] ?? ''}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Remove Upload',
                        onPressed: () async {
                          // Show confirmation dialog
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  title: const Text('Confirm Deletion'),
                                  content: const Text(
                                    'Are you sure you want to remove this physical certificate upload?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed:
                                          () =>
                                              Navigator.of(context).pop(false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed:
                                          () => Navigator.of(context).pop(true),
                                      child: const Text(
                                        'Delete',
                                        style: TextStyle(color: Colors.red),
                                      ),
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

class _IssuedCertsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('certificates')
              .orderBy('issueDate', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text('No issued certificates found.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;

            // Parse the issue date
            DateTime? issueDate;
            try {
              if (data['issueDate'] != null) {
                issueDate = DateTime.parse(data['issueDate']);
              }
            } catch (e) {
              // Handle parsing error
            }

            // Parse the expiry date
            String expiryDateText = '';
            if (data['expiryDate'] != null) {
              try {
                final expiryDate = DateTime.parse(data['expiryDate']);
                expiryDateText =
                    'Expiry Date: ${expiryDate.toString().split(' ')[0]}';
              } catch (e) {
                expiryDateText = 'Expiry Date: Invalid format';
              }
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                title: Text('Certificate: ${data['name'] ?? 'Unknown'}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Organization: ${data['organization'] ?? 'Unknown'}'),
                    Text('Purpose: ${data['purpose'] ?? 'Unknown'}'),
                    if (issueDate != null)
                      Text('Issue Date: ${issueDate.toString().split(' ')[0]}'),
                    if (expiryDateText.isNotEmpty) Text(expiryDateText),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Delete Certificate',
                  onPressed: () async {
                    // Show confirmation dialog
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: const Text('Confirm Deletion'),
                            content: const Text(
                              'Are you sure you want to delete this certificate? This action cannot be undone.',
                            ),
                            actions: [
                              TextButton(
                                onPressed:
                                    () => Navigator.of(context).pop(false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed:
                                    () => Navigator.of(context).pop(true),
                                child: const Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                    );

                    if (confirmed == true) {
                      await doc.reference.delete();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Certificate deleted.')),
                      );
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
