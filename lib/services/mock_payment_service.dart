class MockPaymentService {
  // This is a mock service for testing purposes
  // In production, you would use a real backend server
  
  static Future<Map<String, dynamic>> createPaymentIntent({
    required double amount,
    required String currency,
    required String description,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    // Mock payment intent response
    return {
      'client_secret': 'pi_mock_secret_${DateTime.now().millisecondsSinceEpoch}',
      'id': 'pi_mock_${DateTime.now().millisecondsSinceEpoch}',
      'amount': (amount * 100).round(),
      'currency': currency,
      'status': 'requires_payment_method',
    };
  }

  // Simulate payment confirmation
  static Future<bool> confirmPayment(String paymentIntentId) async {
    await Future.delayed(const Duration(seconds: 2));
    // Simulate 90% success rate
    return DateTime.now().millisecondsSinceEpoch % 10 != 0;
  }

  // Get payment status
  static Future<String> getPaymentStatus(String paymentIntentId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return 'succeeded';
  }
} 