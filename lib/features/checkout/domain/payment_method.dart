import 'package:flutter/material.dart';

/// Supported payment methods for transaction settlement.
enum PaymentMethod {
  cash,
  card,
  digitalWallet;

  String get displayName {
    switch (this) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.card:
        return 'Credit / Debit Card';
      case PaymentMethod.digitalWallet:
        return 'Digital Wallet (Apple/Google Pay)';
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentMethod.cash:
        return Icons.payments_outlined;
      case PaymentMethod.card:
        return Icons.credit_card_outlined;
      case PaymentMethod.digitalWallet:
        return Icons.contactless_outlined;
    }
  }
}
