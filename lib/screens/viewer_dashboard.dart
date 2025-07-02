import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

class ViewerDashboard extends StatelessWidget {
  const ViewerDashboard({super.key});

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  void _goToSharedCertificates(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ViewerSharedLinksScreen()),
    );
  }

  void _showAuthenticationDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Authenticate Access'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Enter Access Code',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Access code "${controller.text}" authenticated.')),
              );
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _verifyCertificateDialog(BuildContext context) {
    final certController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Verify Certificate'),
        content: TextField(
          controller: certController,
          decoration: const InputDecoration(
            labelText: 'Enter Certificate ID',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Certificate ID "${certController.text}" is valid.')),
              );
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  ButtonStyle _standardButtonStyle() {
    return ElevatedButton.styleFrom(
      minimumSize: const Size.fromHeight(56),
      backgroundColor: Colors.teal,
      foregroundColor: Colors.white,
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _featureRow(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: Colors.teal, size: 22),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 15))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: Colors.teal[50],
      appBar: AppBar(
        title: const Text('Viewer Dashboard'),
        backgroundColor: Colors.teal,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
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
                      Navigator.of(context).pop();
                      _logout(context);
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
                builder: (context) => AlertDialog(
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
                        Navigator.of(context).pop();
                        _logout(context);
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
                  Icon(Icons.remove_red_eye, size: 48, color: Colors.white),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Digital Certificate Viewer',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Easily verify and access certificates securely.',
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
                      child: const Icon(Icons.visibility, color: Colors.teal, size: 36),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Welcome, Viewer!',
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

            // Action Buttons in a Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.2,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.link),
                  label: const Text('Shared Links'),
                  style: _standardButtonStyle(),
                  onPressed: () => _goToSharedCertificates(context),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.lock_open),
                  label: const Text('Authenticate'),
                  style: _standardButtonStyle(),
                  onPressed: () => _showAuthenticationDialog(context),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.verified),
                  label: const Text('Verify Cert'),
                  style: _standardButtonStyle(),
                  onPressed: () => _verifyCertificateDialog(context),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.info_outline),
                  label: const Text('Help & Info'),
                  style: _standardButtonStyle(),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Help & Info'),
                        content: const Text('Contact support@digitalcert.com for help or visit our FAQ.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Feature List Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Viewer Features:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _featureRow(Icons.link, 'Access shared certificate links.'),
                    const SizedBox(height: 10),
                    _featureRow(Icons.lock_open, 'Authenticate before access.'),
                    const SizedBox(height: 10),
                    _featureRow(Icons.verified, 'Verify certificate authenticity.'),
                    const SizedBox(height: 10),
                    _featureRow(Icons.info_outline, 'Get help and information.'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

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
                        'Tip: Always verify the certificate ID before trusting a document.',
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
    );
  }
}

class ViewerSharedLinksScreen extends StatelessWidget {
  const ViewerSharedLinksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock shared links data
    final List<Map<String, String>> sharedLinks = [
      {
        'title': 'Certificate of Achievement',
        'link': 'https://your-app.web.app/shared/abc123',
        'expires': '2024-07-31',
      },
      {
        'title': 'Donation Certificate',
        'link': 'https://your-app.web.app/shared/def456',
        'expires': '2024-08-15',
      },
      {
        'title': 'Membership Proof',
        'link': 'https://your-app.web.app/shared/ghi789',
        'expires': '2024-09-01',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shared Links'),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
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
                          'Your Shared Certificate Links',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Access certificates shared with you. Tap to copy or open.',
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

            // Shared Links List
            if (sharedLinks.isEmpty)
              Center(
                child: Text(
                  'No shared links available.',
                  style: TextStyle(fontSize: 16, color: Colors.teal[700]),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sharedLinks.length,
                separatorBuilder: (_, __) => const SizedBox(height: 18),
                itemBuilder: (context, index) {
                  final link = sharedLinks[index];
                  return Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.description, color: Colors.teal[400]),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  link['title']!,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.teal[50],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.timer, size: 16, color: Colors.teal),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Exp: ${link['expires']}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.teal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          SelectableText(
                            link['link']!,
                            style: const TextStyle(
                              color: Colors.blueAccent,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              ElevatedButton.icon(
                                icon: const Icon(Icons.copy),
                                label: const Text('Copy'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(90, 36),
                                ),
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: link['link']!));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Link copied to clipboard')),
                                  );
                                },
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.open_in_new),
                                label: const Text('Open'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.teal,
                                  side: const BorderSide(color: Colors.teal),
                                  minimumSize: const Size(90, 36),
                                ),
                                onPressed: () {
                                  // You can use url_launcher to open the link in a real app
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 32),

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
                        'Tip: Shared links may expire. Copy or open them before the expiry date.',
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
    );
  }
}
