import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DonationService {
  // TODO: Replace with your actual backend URL
  static const String _backendUrl = 'https://your-backend-url.com';

  // TODO: Replace with your actual Stripe secret key (keep this secure on your backend)
  static const String _stripeSecretKey = 'sk_test_your_stripe_secret_key_here';

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Create a payment intent on the backend
  static Future<Map<String, dynamic>> createPaymentIntent({
    required double amount,
    required String currency,
    String? email,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/create-payment-intent'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_stripeSecretKey',
        },
        body: json.encode({
          'amount': (amount * 100).round(), // Convert to cents
          'currency': currency,
          'email': email,
          'metadata': {
            'donation_type': 'digital_certificate_repository',
            'platform': 'flutter_app',
          },
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Failed to create payment intent: ${response.statusCode}',
        );
      }
    } catch (e) {
      // For demo purposes, return a mock response
      // In production, this should be handled by your backend
      return {
        'client_secret': 'mock_client_secret_for_demo_purposes',
        'id': 'pi_mock_${DateTime.now().millisecondsSinceEpoch}',
        'amount': (amount * 100).round(),
        'currency': currency,
      };
    }
  }

  /// Save donation record to Firestore (and locally for fallback)
  static Future<void> saveDonationRecord({
    required double amount,
    required String currency,
    String? transactionId,
    String? status,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('donations').add({
          'uid': user.uid,
          'email': user.email,
          'amount': amount,
          'currency': currency,
          'transactionId': transactionId,
          'status': status ?? 'completed',
          'date': DateTime.now().toIso8601String(),
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Failed to save donation to Firestore: $e');
    }
    // Also save locally for fallback
    try {
      final prefs = await SharedPreferences.getInstance();
      final donations = prefs.getStringList('donations') ?? [];
      final donationRecord = {
        'amount': amount,
        'currency': currency,
        'transactionId': transactionId,
        'status': status ?? 'completed',
        'date': DateTime.now().toIso8601String(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      donations.add(json.encode(donationRecord));
      await prefs.setStringList('donations', donations);
    } catch (e) {
      print('Failed to save donation record locally: $e');
    }
  }

  /// Get all donation records for the current user from Firestore
  static Future<List<Map<String, dynamic>>> getDonationHistory() async {
    final user = _auth.currentUser;
    if (user == null) return [];
    try {
      final query =
          await _firestore
              .collection('donations')
              .where('uid', isEqualTo: user.uid)
              .get();
      final docs =
          query.docs.map((doc) {
            final data = doc.data();
            // Ensure all required fields exist for old records
            return {
              'amount': data['amount'],
              'currency': data['currency'] ?? 'myr',
              'transactionId': data['transactionId'],
              'status': data['status'] ?? 'completed',
              'date': data['date'] ?? '',
              'timestamp': data['timestamp'] ?? 0,
            };
          }).toList();
      // Sort by timestamp if available, else by date string
      docs.sort((a, b) {
        final tA = a['timestamp'] ?? 0;
        final tB = b['timestamp'] ?? 0;
        if (tA != 0 && tB != 0) return tB.compareTo(tA);
        return (b['date'] ?? '').compareTo(a['date'] ?? '');
      });
      return docs;
    } catch (e) {
      print('Failed to get donation history from Firestore: $e');
      // fallback to local
      try {
        final prefs = await SharedPreferences.getInstance();
        final donations = prefs.getStringList('donations') ?? [];
        return donations.map((donation) {
          final data = json.decode(donation) as Map<String, dynamic>;
          return {
            'amount': data['amount'],
            'currency': data['currency'] ?? 'myr',
            'transactionId': data['transactionId'],
            'status': data['status'] ?? 'completed',
            'date': data['date'] ?? '',
            'timestamp': data['timestamp'] ?? 0,
          };
        }).toList();
      } catch (e) {
        print('Failed to get donation history locally: $e');
        return [];
      }
    }
  }

  /// Get total donation amount for the current user from Firestore
  static Future<double> getTotalDonations() async {
    final donations = await getDonationHistory();
    double total = 0.0;
    for (final donation in donations) {
      if (donation['status'] == 'completed') {
        total += (donation['amount'] as num).toDouble();
      }
    }
    return total;
  }

  /// Validate donation amount
  static bool isValidDonationAmount(double amount) {
    return amount > 0 && amount <= 10000; // Max RM 10,000
  }

  /// Format currency
  static String formatCurrency(double amount, String currency) {
    switch (currency.toLowerCase()) {
      case 'myr':
        return 'RM${amount.toStringAsFixed(2)}';
      case 'usd':
        return '\$${amount.toStringAsFixed(2)}';
      case 'eur':
        return '€${amount.toStringAsFixed(2)}';
      default:
        return '${amount.toStringAsFixed(2)} $currency';
    }
  }

  /// Send donation receipt email (mock implementation)
  static Future<bool> sendDonationReceipt({
    required String email,
    required double amount,
    required String currency,
    String? transactionId,
  }) async {
    try {
      // In production, this would send an actual email
      // For demo purposes, we'll just simulate success
      await Future.delayed(Duration(seconds: 1));

      print(
        'Donation receipt sent to $email for ${formatCurrency(amount, currency)}',
      );
      return true;
    } catch (e) {
      print('Failed to send donation receipt: $e');
      return false;
    }
  }

  /// Get donation statistics for the current user from Firestore
  static Future<Map<String, dynamic>> getDonationStats() async {
    final donations = await getDonationHistory();
    final completedDonations =
        donations.where((d) => d['status'] == 'completed').toList();
    if (completedDonations.isEmpty) {
      return {
        'totalAmount': 0.0,
        'totalDonations': 0,
        'averageAmount': 0.0,
        'lastDonation': null,
      };
    }
    final totalAmount = completedDonations.fold<double>(
      0.0,
      (sum, donation) => sum + (donation['amount'] as num).toDouble(),
    );
    final averageAmount = totalAmount / completedDonations.length;
    completedDonations.sort(
      (a, b) => (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0),
    );
    final lastDonation = completedDonations.first;
    return {
      'totalAmount': totalAmount,
      'totalDonations': completedDonations.length,
      'averageAmount': averageAmount,
      'lastDonation': lastDonation,
    };
  }
}
