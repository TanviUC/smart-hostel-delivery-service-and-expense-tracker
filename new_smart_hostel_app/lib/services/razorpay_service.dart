import 'dart:async';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class RazorpayService {
  late Razorpay _razorpay;
  String? lastPaymentId;
  Completer<String?>? _paymentCompleter;

  RazorpayService() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void dispose() {
    _razorpay.clear();
  }

  /// Process payment in rupees (amount is in rupees, converted to paise)
  Future<String?> processPayment(
      int amountInRupees, BuildContext context,
      {String description = "Payment"}) async {
    // Prevent multiple concurrent payments
    if (_paymentCompleter != null && !_paymentCompleter!.isCompleted) {
      return _paymentCompleter!.future;
    }

    lastPaymentId = null;
    _paymentCompleter = Completer<String?>();

    final options = {
      'key': 'rzp_test_RUCF0ZsGSXqnfb',
      'amount': amountInRupees * 100, // ✅ Razorpay expects paise
      'name': 'Smart Hostel Delivery',
      'description': description,
      'prefill': {
        'contact': '9999999999', // valid test number
        'email': 'test@example.com',
      },
      'theme': {'color': '#0077FF'},
      'retry': {'enabled': true, 'max_count': 1}, // allow retry once
    };

    try {
      debugPrint("💳 Razorpay options: $options");
      _razorpay.open(options);

      return _paymentCompleter!.future.timeout(
        const Duration(seconds: 120), // allow 2 minutes for test
        onTimeout: () {
          if (!_paymentCompleter!.isCompleted) {
            _paymentCompleter!.complete(null);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Payment timed out ⏱️"),
                backgroundColor: Colors.red,
              ),
            );
          }
          return null;
        },
      );
    } catch (e) {
      debugPrint("❌ Razorpay open error: $e");
      if (!_paymentCompleter!.isCompleted) {
        _paymentCompleter!.complete(null);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Payment failed: $e"),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    lastPaymentId = response.paymentId;
    debugPrint("✅ Payment Success: ${response.paymentId}");
    if (_paymentCompleter != null && !_paymentCompleter!.isCompleted) {
      _paymentCompleter!.complete(lastPaymentId);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint("❌ Payment Error: ${response.code} | ${response.message}");
    if (_paymentCompleter != null && !_paymentCompleter!.isCompleted) {
      _paymentCompleter!.complete(null);
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint("💼 External wallet selected: ${response.walletName}");
  }
}
