import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'mock_payment_service.dart';

class StripeService {
  // Replace with your actual Stripe publishable key
  static const String _publishableKey = 'pk_test_your_publishable_key_here';

  static Future<void> initialize() async {
    Stripe.publishableKey = _publishableKey;
    await Stripe.instance.applySettings();
  }

  static Future<void> makeDonation({
    required double amount,
    required String currency,
    required String description,
  }) async {
    try {
      // For testing, use mock service instead of real backend
      final paymentIntent = await MockPaymentService.createPaymentIntent(
        amount: amount,
        currency: currency,
        description: description,
      );
      
      // Present payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntent['client_secret'],
          merchantDisplayName: 'Digital Certificate App',
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      // Simulate payment confirmation
      final success = await MockPaymentService.confirmPayment(paymentIntent['id']);
      
      if (success) {
        // Save donation record to Firestore
        await _saveDonationRecord(amount, currency, description);
      } else {
        throw Exception('Payment was declined');
      }

    } catch (e) {
      throw Exception('Payment failed: $e');
    }
  }

  static Future<void> _saveDonationRecord(
    double amount,
    String currency,
    String description,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    
    await FirebaseFirestore.instance.collection('donations').add({
      'amount': amount,
      'currency': currency,
      'description': description,
      'donorEmail': user?.email ?? 'anonymous',
      'donorId': user?.uid,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'completed',
    });
  }

  // For testing purposes - create a simple donation without backend
  static Future<void> makeTestDonation({
    required double amount,
    required String description,
  }) async {
    try {
      // Simulate payment processing
      await Future.delayed(const Duration(seconds: 2));
      
      // Save donation record to Firestore (for testing)
      await _saveDonationRecord(amount, 'USD', description);
    } catch (e) {
      throw Exception('Test donation failed: $e');
    }
  }

  // Get donation history
  static Stream<QuerySnapshot> getDonationHistory() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return FirebaseFirestore.instance
          .collection('donations')
          .where('donorId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .snapshots();
    } else {
      return FirebaseFirestore.instance
          .collection('donations')
          .orderBy('timestamp', descending: true)
          .limit(10)
          .snapshots();
    }
  }

  // Get total donations
  static Future<double> getTotalDonations() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('donations')
        .where('status', isEqualTo: 'completed')
        .get();
    
    double total = 0;
    for (var doc in snapshot.docs) {
      total += (doc.data()['amount'] as num).toDouble();
    }
    return total;
  }
} 