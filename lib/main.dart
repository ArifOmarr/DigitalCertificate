import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

import 'screens/login_screen.dart';
import 'screens/recipient_dashboard.dart';
import 'screens/ca_dashboard.dart';
import 'screens/admin_dashboard.dart';
import 'screens/viewer_dashboard.dart';
import 'screens/recipient_certificates_screen.dart';
import 'screens/ca_certificate_approval_screen.dart';
import 'screens/shared_certificate_screen.dart';
import 'screens/ca_create_certificate_screen.dart';
import 'screens/recipient_certificate_upload_screen.dart';
import 'screens/donation_screen.dart';
import 'screens/donation_history_screen.dart';
import 'screens/shared_certificate_screen.dart';
import 'screens/client_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Digital Certificate App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: const AuthWrapper(),
      routes: {
        '/recipient_dashboard': (context) => const RecipientDashboard(),
        '/ca_dashboard': (context) => const CaDashboard(),
        '/admin_dashboard': (context) => const AdminDashboard(),
        '/viewer_dashboard': (context) => const ViewerDashboard(),
        '/client_dashboard': (context) => const ClientDashboard(),
        '/recipient_certificates':
            (context) => const RecipientCertificatesScreen(),
        '/ca_approvals': (context) => const CaCertificateApprovalScreen(),
        '/ca_dashboard/create_certificate':
            (context) => const CaCreateCertificateScreen(),
        '/recipient_upload':
            (context) => const RecipientCertificateUploadScreen(),
        '/donation': (context) => const DonationScreen(),
        '/donation_history': (context) => const DonationHistoryScreen(),
        '/share_certificate': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map;
          return ShareCertificateScreen(certificateId: args['certificateId']);
        },
      },
      onGenerateRoute: (settings) {
        if (settings.name != null && settings.name!.startsWith('/shared/')) {
          final token = settings.name!.substring('/shared/'.length);
          return MaterialPageRoute(
            builder: (_) => ShareCertificateScreen(certificateId: token),
          );
        }
        return null;
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const LoginScreen();
    } else {
      return FutureBuilder<DocumentSnapshot>(
        future:
            FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData && snapshot.data!.exists) {
            final role = snapshot.data!['role'];
            if (role == 'recipient') {
              return const RecipientDashboard();
            } else if (role == 'ca') {
              return const CaDashboard();
            } else if (role == 'admin') {
              return const AdminDashboard();
            } else if (role == 'viewer') {
              return const ViewerDashboard();
            } else if (role == 'client') {
              return const ClientDashboard();
            } else {
              return const Scaffold(body: Center(child: Text('Unknown role')));
            }
          }
          return const Scaffold(
            body: Center(child: Text('User data not found')),
          );
        },
      );
    }
  }
}
