import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DonationService {
  // TODO: Replace with your actual backend URL
  static const String _backendUrl = 'https://your-backend-url.com';

  // TODO: Replace with your actual Stripe secret key (keep this secure on your backend)
  static const String _stripeSecretKey = 'sk_test_your_stripe_secret_key_here';

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

  /// Save donation record locally
  static Future<void> saveDonationRecord({
    required double amount,
    required String currency,
    String? transactionId,
    String? status,
  }) async {
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
      print('Failed to save donation record: $e');
      rethrow;
    }
  }

  /// Get all donation records
  static Future<List<Map<String, dynamic>>> getDonationHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final donations = prefs.getStringList('donations') ?? [];

      return donations.map((donation) {
        return json.decode(donation) as Map<String, dynamic>;
      }).toList();
    } catch (e) {
      print('Failed to get donation history: $e');
      return [];
    }
  }

  /// Get total donation amount
  static Future<double> getTotalDonations() async {
    try {
      final donations = await getDonationHistory();
      double total = 0.0;

      for (final donation in donations) {
        if (donation['status'] == 'completed') {
          total += (donation['amount'] as num).toDouble();
        }
      }

      return total;
    } catch (e) {
      print('Failed to calculate total donations: $e');
      return 0.0;
    }
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

  /// Get donation statistics
  static Future<Map<String, dynamic>> getDonationStats() async {
    try {
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

      // Sort by timestamp to get the latest donation
      completedDonations.sort(
        (a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int),
      );
      final lastDonation = completedDonations.first;

      return {
        'totalAmount': totalAmount,
        'totalDonations': completedDonations.length,
        'averageAmount': averageAmount,
        'lastDonation': lastDonation,
      };
    } catch (e) {
      print('Failed to get donation stats: $e');
      return {
        'totalAmount': 0.0,
        'totalDonations': 0,
        'averageAmount': 0.0,
        'lastDonation': null,
      };
    }
  }
}
