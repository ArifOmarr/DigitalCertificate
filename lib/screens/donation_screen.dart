import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DonationScreen extends StatefulWidget {
  const DonationScreen({super.key});

  @override
  State<DonationScreen> createState() => _DonationScreenState();
}

class _DonationScreenState extends State<DonationScreen> {
  final List<double> _donationAmounts = [5.0, 10.0, 25.0, 50.0, 100.0];
  double? _selectedAmount;
  double _customAmount = 0.0;
  bool _isCustomAmount = false;
  bool _isProcessing = false;
  bool _isLoading = true;
  String? _errorMessage;

  // TODO: Replace with your actual Stripe publishable key
  static const String _stripePublishableKey =
      'pk_test_your_stripe_publishable_key_here';

  // TODO: Replace with your actual backend URL
  static const String _backendUrl = 'https://your-backend-url.com';

  @override
  void initState() {
    super.initState();
    _initializeStripe();
  }

  Future<void> _initializeStripe() async {
    try {
      Stripe.publishableKey = _stripePublishableKey;
      await Stripe.instance.applySettings();
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize payment system: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _processPayment() async {
    if (_selectedAmount == null && !_isCustomAmount) {
      setState(() {
        _errorMessage = 'Please select a donation amount';
      });
      return;
    }

    final amount = _isCustomAmount ? _customAmount : _selectedAmount!;
    if (amount <= 0) {
      setState(() {
        _errorMessage = 'Please enter a valid donation amount';
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      // Create payment intent on your backend
      final paymentIntent = await _createPaymentIntent(amount);

      // Configure payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntent['client_secret'],
          merchantDisplayName: 'Digital Certificate Repository',
          style: ThemeMode.system,
          appearance: PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(primary: Colors.teal),
          ),
        ),
      );

      // Present payment sheet
      await Stripe.instance.presentPaymentSheet();

      // Payment successful
      await _saveDonationRecord(amount);
      _showSuccessDialog(amount);
    } catch (e) {
      setState(() {
        _errorMessage = 'Payment failed: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<Map<String, dynamic>> _createPaymentIntent(double amount) async {
    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/create-payment-intent'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'amount': (amount * 100).round(), // Convert to cents
          'currency': 'myr', // Malaysian Ringgit
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to create payment intent');
      }
    } catch (e) {
      // For demo purposes, return a mock payment intent
      // In production, this should be handled by your backend
      return {'client_secret': 'mock_client_secret_for_demo'};
    }
  }

  Future<void> _saveDonationRecord(double amount) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final donations = prefs.getStringList('donations') ?? [];
      final donationRecord = {
        'amount': amount,
        'date': DateTime.now().toIso8601String(),
        'status': 'completed',
      };
      donations.add(json.encode(donationRecord));
      await prefs.setStringList('donations', donations);
    } catch (e) {
      print('Failed to save donation record: $e');
    }
  }

  void _showSuccessDialog(double amount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 28),
                SizedBox(width: 8),
                Text('Thank You!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Your donation of RM${amount.toStringAsFixed(2)} has been received successfully!',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 16),
                Text(
                  'Your support helps us maintain and improve the Digital Certificate Repository service.',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(); // Return to previous screen
                },
                child: Text('Continue'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Donate'), backgroundColor: Colors.teal),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.teal),
              SizedBox(height: 16),
              Text('Initializing payment system...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.teal[50],
      appBar: AppBar(
        title: Text('Support Our Project'),
        backgroundColor: Colors.teal,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.teal, Colors.teal[700]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(Icons.favorite, color: Colors.white, size: 48),
                  SizedBox(height: 16),
                  Text(
                    'Support Digital Certificate Repository',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Help us maintain and improve our secure certificate management platform',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            SizedBox(height: 32),

            // Donation Amounts Section
            Text(
              'Choose Your Donation Amount',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 16),

            // Predefined amounts
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children:
                  _donationAmounts.map((amount) {
                    final isSelected =
                        _selectedAmount == amount && !_isCustomAmount;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedAmount = amount;
                          _isCustomAmount = false;
                          _errorMessage = null;
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.teal : Colors.white,
                          border: Border.all(
                            color: isSelected ? Colors.teal : Colors.grey[300]!,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow:
                              isSelected
                                  ? [
                                    BoxShadow(
                                      color: Colors.teal.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: Offset(0, 4),
                                    ),
                                  ]
                                  : null,
                        ),
                        child: Text(
                          'RM${amount.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.grey[800],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),

            SizedBox(height: 24),

            // Custom amount
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _isCustomAmount = true;
                        _selectedAmount = null;
                        _errorMessage = null;
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: _isCustomAmount ? Colors.teal : Colors.white,
                        border: Border.all(
                          color:
                              _isCustomAmount ? Colors.teal : Colors.grey[300]!,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Custom Amount',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color:
                              _isCustomAmount ? Colors.white : Colors.grey[800],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            if (_isCustomAmount) ...[
              SizedBox(height: 16),
              TextField(
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Enter Amount (RM)',
                  prefixText: 'RM ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.teal, width: 2),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _customAmount = double.tryParse(value) ?? 0.0;
                    _errorMessage = null;
                  });
                },
              ),
            ],

            SizedBox(height: 32),

            // Benefits Section
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Support Helps Us:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildBenefitItem(
                    Icons.security,
                    'Maintain Security Standards',
                  ),
                  _buildBenefitItem(
                    Icons.storage,
                    'Improve Storage Infrastructure',
                  ),
                  _buildBenefitItem(Icons.code, 'Develop New Features'),
                  _buildBenefitItem(
                    Icons.support_agent,
                    'Provide Better Support',
                  ),
                ],
              ),
            ),

            SizedBox(height: 32),

            // Error message
            if (_errorMessage != null)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  border: Border.all(color: Colors.red[200]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ),
                  ],
                ),
              ),

            SizedBox(height: 24),

            // Donate Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                onPressed: _isProcessing ? null : _processPayment,
                child:
                    _isProcessing
                        ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Processing Payment...'),
                          ],
                        )
                        : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.payment),
                            SizedBox(width: 8),
                            Text(
                              'Donate Now',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
              ),
            ),

            SizedBox(height: 16),

            // Security notice
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                border: Border.all(color: Colors.blue[200]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.security, color: Colors.blue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your payment is secured by Stripe. We never store your payment information.',
                      style: TextStyle(color: Colors.blue[700], fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }
}
