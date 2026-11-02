import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../checkout/domain/tax_rate.dart';
import '../../../pos/providers/cart_provider.dart';

/// Interactive tax selector component allowing cashiers to toggle tax structures on the fly.
class TaxSelectorWidget extends ConsumerWidget {
  const TaxSelectorWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartNotifierProvider);
    final activeTax = cartState.taxRate;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: AppDimens.radiusMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(
                Icons.percent,
                size: 18,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tax Structure',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '${activeTax.name} (${activeTax.ratePercent.toStringAsFixed(1)}%)',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          PopupMenuButton<TaxRate>(
            tooltip: 'Select Tax Regime',
            icon: const Icon(
              Icons.arrow_drop_down_circle_outlined,
              color: AppColors.primary,
              size: 20,
            ),
            onSelected: (selectedRate) {
              ref.read(cartNotifierProvider.notifier).setTaxRate(selectedRate);
            },
            itemBuilder: (context) {
              return TaxRate.defaultRates.map((rate) {
                final isSelected = rate.id == activeTax.id;
                return PopupMenuItem<TaxRate>(
                  value: rate,
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        size: 18,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textMuted,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              rate.name,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSelected
                                    ? AppColors.primaryDark
                                    : AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              rate.type.displayName,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList();
            },
          ),
        ],
      ),
    );
  }
}
