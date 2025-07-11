import 'package:flutter/material.dart';

class DonationScreen extends StatefulWidget {
  const DonationScreen({super.key});

  @override
  State<DonationScreen> createState() => _DonationScreenState();
}

class _DonationScreenState extends State<DonationScreen> {
  final _formKey = GlobalKey<FormState>();
  double _selectedAmount = 10.0;
  String _customAmount = '';
  String _selectedPaymentMethod = '';
  bool _isProcessing = false;
  String _donorName = '';
  String _donorEmail = '';

  final List<double> _presetAmounts = [5.0, 10.0, 25.0, 50.0, 100.0];
  
  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'id': 'maybank',
      'name': 'Maybank',
      'icon': Icons.account_balance,
      'color': Colors.orange,
      'accountNumber': '1234-5678-9012',
      'accountName': 'Digital Certificate Project',
    },
    {
      'id': 'cimb',
      'name': 'CIMB Bank',
      'icon': Icons.account_balance,
      'color': Colors.blue,
      'accountNumber': '9876-5432-1098',
      'accountName': 'Digital Certificate Project',
    },
    {
      'id': 'public',
      'name': 'Public Bank',
      'icon': Icons.account_balance,
      'color': Colors.green,
      'accountNumber': '1122-3344-5566',
      'accountName': 'Digital Certificate Project',
    },
    {
      'id': 'tng',
      'name': 'Touch \'n Go eWallet',
      'icon': Icons.account_balance_wallet,
      'color': Colors.purple,
      'accountNumber': '012-345-6789',
      'accountName': 'Digital Certificate Project',
    },
  ];

  Future<void> _processDonation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);

    try {
      final amount = _customAmount.isNotEmpty 
          ? double.parse(_customAmount) 
          : _selectedAmount;

      if (amount <= 0) {
        throw Exception('Please enter a valid amount');
      }

      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Donation'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Amount: RM ${amount.toStringAsFixed(2)}'),
              const SizedBox(height: 8),
              Text('Payment Method: ${_getPaymentMethodName(_selectedPaymentMethod)}'),
              const SizedBox(height: 8),
              Text('Donor: $_donorName'),
              const SizedBox(height: 16),
              const Text(
                'You will be redirected to complete the payment.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              child: const Text('Proceed to Payment'),
            ),
          ],
        ),
      );

      if (confirmed != true) {
        setState(() => _isProcessing = false);
        return;
      }

      // Simulate payment processing
      await Future.delayed(const Duration(seconds: 2));

      // Show payment details
      if (mounted) {
        _showPaymentDetails(amount);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  String _getPaymentMethodName(String id) {
    final method = _paymentMethods.firstWhere((m) => m['id'] == id);
    return method['name'];
  }

  void _showPaymentDetails(double amount) {
    final method = _paymentMethods.firstWhere((m) => m['id'] == _selectedPaymentMethod);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            const Text('Payment Details'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Amount: RM ${amount.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            Text('Payment Method: ${method['name']}'),
            const SizedBox(height: 8),
            Text('Account Number: ${method['accountNumber']}'),
            const SizedBox(height: 8),
            Text('Account Name: ${method['accountName']}'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.green[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Please complete the transfer and keep the receipt for reference.',
                      style: TextStyle(
                        color: Colors.green[800],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Thank you for your donation of RM ${amount.toStringAsFixed(2)}!'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 3),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Support Our Project'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.favorite,
                        size: 64,
                        color: Colors.red[400],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Support Digital Certificate App',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Help us maintain and improve our digital certificate platform',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Donor Information
              const Text(
                'Your Information:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
                onSaved: (value) => _donorName = value ?? '',
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
                onSaved: (value) => _donorEmail = value ?? '',
              ),
              const SizedBox(height: 24),

              // Preset amounts
              const Text(
                'Choose an amount:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _presetAmounts.map((amount) {
                  final isSelected = _selectedAmount == amount && _customAmount.isEmpty;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedAmount = amount;
                        _customAmount = '';
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.teal : Colors.grey[200],
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: isSelected ? Colors.teal : Colors.grey[300]!,
                        ),
                      ),
                      child: Text(
                        'RM ${amount.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Custom Amount (RM)',
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    _customAmount = value;
                    if (value.isNotEmpty) {
                      _selectedAmount = 0;
                    }
                  });
                },
              ),
              const SizedBox(height: 24),

              // Payment Methods
              const Text(
                'Select Payment Method:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedPaymentMethod.isEmpty ? null : _selectedPaymentMethod,
                decoration: const InputDecoration(
                  labelText: 'Choose Payment Method',
                  prefixIcon: Icon(Icons.payment),
                  border: OutlineInputBorder(),
                ),
                items: _paymentMethods.map((method) {
                  return DropdownMenuItem<String>(
                    value: method['id'],
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: method['color'],
                          child: Icon(
                            method['icon'],
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          method['name'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPaymentMethod = value ?? '';
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a payment method';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Donate Button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _processDonation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isProcessing
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Processing...'),
                          ],
                        )
                      : const Text(
                          'Donate Now',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 