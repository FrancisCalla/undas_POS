import 'package:flutter_test/flutter_test.dart';
import 'package:pos_bai/core/utils/currency_formatter.dart';
import 'package:pos_bai/core/utils/tax_engine.dart';
import 'package:pos_bai/features/cart/domain/cart_item.dart';
import 'package:pos_bai/features/cart/domain/cart_state.dart';
import 'package:pos_bai/features/catalog/domain/product.dart';
import 'package:pos_bai/features/checkout/domain/tax_rate.dart';

void main() {
  group('POS Minor-Units Philippine Peso (PHP) Currency & Tax Engine Calculations', () {
    test('CurrencyFormatter parses and formats centavos into Philippine Peso without precision loss', () {
      expect(CurrencyFormatter.format(1250), '₱12.50');
      expect(CurrencyFormatter.format(50), '₱0.50');
      expect(CurrencyFormatter.format(0), '₱0.00');
      expect(CurrencyFormatter.format(150000), '₱1,500.00');
      expect(CurrencyFormatter.parseToCents('₱14.99'), 1499);
      expect(CurrencyFormatter.parseToCents('₱1,200.50'), 120050);
      expect(CurrencyFormatter.parseToCents('100'), 10000);
      expect(CurrencyFormatter.parseToCents(''), 0);
      expect(CurrencyFormatter.parseToCents('invalid'), 0);
    });

    test('Exclusive VAT adds tax on top of subtotal', () {
      // Subtotal = ₱100.00 (10000 cents), VAT = 10%
      final result = TaxEngine.calculate(
        subtotalAfterDiscountCents: 10000,
        taxRate: TaxRate.standardExclusive,
      );

      expect(result.netSubtotalCents, 10000);
      expect(result.taxAmountCents, 1000); // 10% of 10000 = 1000
      expect(result.finalTotalCents, 11000); // ₱110.00
    });

    test('Inclusive VAT computes embedded tax from gross subtotal', () {
      // Gross Total = ₱110.00 (11000 cents), VAT = 10%
      final result = TaxEngine.calculate(
        subtotalAfterDiscountCents: 11000,
        taxRate: TaxRate.standardInclusive,
      );

      // Base = 11000 / 1.1 = 10000 cents. Tax = 1000 cents.
      expect(result.taxAmountCents, 1000);
      expect(result.netSubtotalCents, 10000);
      expect(result.finalTotalCents, 11000);
    });

    test('Tax-exempt rate calculates zero tax', () {
      final result = TaxEngine.calculate(
        subtotalAfterDiscountCents: 50000,
        taxRate: TaxRate.zeroTax,
      );

      expect(result.taxAmountCents, 0);
      expect(result.netSubtotalCents, 50000);
      expect(result.finalTotalCents, 50000);
    });

    test('CartState aggregates line items, item discounts, and global order discounts in PHP', () {
      const productA = Product(
        id: 'p1',
        sku: 'SKU-1',
        barcode: '111',
        name: 'Red Roses Bouquet',
        priceCents: 120000, // ₱1,200.00
        stockQty: 10,
        categoryId: 'cat_flowers',
      );

      const productB = Product(
        id: 'p2',
        sku: 'SKU-2',
        barcode: '222',
        name: 'Vanilla Soy Candle',
        priceCents: 35000, // ₱350.00
        stockQty: 10,
        categoryId: 'cat_candles',
      );

      // Item 1: 2x Roses = ₱2,400.00 (240000 cents), 10% item discount = ₱240.00 (24000 cents off) -> ₱2,160.00
      const item1 = CartItem(
        product: productA,
        quantity: 2,
        discountPercent: 10.0,
      );

      // Item 2: 1x Candle = ₱350.00 (35000 cents), 0% discount -> ₱350.00
      const item2 = CartItem(
        product: productB,
        quantity: 1,
        discountPercent: 0.0,
      );

      // Cart with 10% global order discount and 10% Exclusive VAT
      const cart = CartState(
        items: [item1, item2],
        globalDiscountPercent: 10.0,
        taxRate: TaxRate.standardExclusive,
      );

      expect(cart.totalItemCount, 3);
      expect(cart.grossSubtotalCents, 275000); // 240000 + 35000 = ₱2,750.00
      expect(cart.lineItemDiscountsCents, 24000); // ₱240.00 off item1
      expect(cart.subtotalAfterLineDiscountsCents, 251000); // ₱2,510.00
      expect(cart.globalDiscountCents, 25100); // 10% of 251000 = ₱251.00
      expect(cart.taxableSubtotalCents, 225900); // 251000 - 25100 = ₱2,259.00
      // 10% Exclusive VAT on 225900 = 22590 cents (₱225.90)
      expect(cart.taxCents, 22590);
      // Grand Total = 225900 + 22590 = 248490 cents (₱2,484.90)
      expect(cart.grandTotalCents, 248490);
    });

    test('Cash change computation in Philippine Peso handles exact and excess tender', () {
      const grandTotalCents = 125000; // ₱1,250.00

      // Exact tender: ₱1,250.00
      const exactTender = 125000;
      final exactChange = exactTender - grandTotalCents;
      expect(exactChange, 0);

      // Excess tender: ₱1,500.00 (e.g. 1x ₱1000 + 1x ₱500)
      const excessTender = 150000;
      final excessChange = excessTender - grandTotalCents;
      expect(excessChange, 25000); // ₱250.00 change
      expect(CurrencyFormatter.format(excessChange), '₱250.00');
    });
  });
}
