import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

typedef PaymentSuccessCallback = Future<void> Function(String paymentId);
typedef PaymentErrorCallback =
    Future<void> Function(String code, String message);

class PaymentService {
  PaymentService._internal();
  static final PaymentService instance = PaymentService._internal();

  Razorpay? _razorpay;

  void initialize({
    required PaymentSuccessCallback onSuccess,
    required PaymentErrorCallback onError,
  }) {
    _razorpay ??= Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, (
      PaymentSuccessResponse r,
    ) async {
      await onSuccess(r.paymentId ?? '');
    });
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, (
      PaymentFailureResponse r,
    ) async {
      await onError('${r.code}', r.message ?? 'Unknown error');
    });
  }

  void dispose() {
    _razorpay?.clear();
    _razorpay = null;
  }

  void pay({
    String? orderId,
    required String key,
    required double amountInRupees,
    required String name,
    required String description,
    String? prefillEmail,
    String? prefillContact,
    bool upiOnly = false,
  }) {
    final options = {
      'key': key,
      'amount': (amountInRupees * 100).round(),
      'name': name,
      'description': description,
      'prefill': {'contact': prefillContact ?? '', 'email': prefillEmail ?? ''},
      'timeout': 120,
      'theme': {'color': '#34A853'},
    };
    if (orderId != null && orderId.isNotEmpty) {
      options['order_id'] = orderId;
    }

    // Restrict to UPI only when requested
    if (upiOnly) {
      options['method'] = 'upi';
      options['upi'] = {
        // Use intent flow to open UPI apps like GPay/PhonePe/Paytm
        'flow': 'intent',
      };
      options['config'] = {
        'display': {
          // Hide all other payment methods in Checkout
          'hide': [
            {'method': 'card'},
            {'method': 'netbanking'},
            {'method': 'wallet'},
            {'method': 'emi'},
            {'method': 'paylater'},
          ],
        },
      };
    }
    if (kDebugMode) {
      print('Opening Razorpay with options: $options');
    }
    _razorpay?.open(options);
  }
}
