import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';

/// Modal dialog for applying line-item or order-level percentage discounts.
class DiscountDialog extends StatefulWidget {
  final String title;
  final double currentDiscountPercent;

  const DiscountDialog({
    super.key,
    required this.title,
    required this.currentDiscountPercent,
  });

  @override
  State<DiscountDialog> createState() => _DiscountDialogState();
}

class _DiscountDialogState extends State<DiscountDialog> {
  late final TextEditingController _controller;
  double _selectedPercent = 0.0;

  @override
  void initState() {
    super.initState();
    _selectedPercent = widget.currentDiscountPercent;
    _controller = TextEditingController(
      text: widget.currentDiscountPercent > 0
          ? widget.currentDiscountPercent.toStringAsFixed(0)
          : '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setPercent(double val) {
    setState(() {
      _selectedPercent = val;
      _controller.text = val > 0 ? val.toStringAsFixed(0) : '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final quickPresets = [0.0, 5.0, 10.0, 15.0, 20.0, 50.0];

    return AlertDialog(
      title: Text(
        widget.title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      shape: const RoundedRectangleBorder(borderRadius: AppDimens.radiusLg),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select a preset or enter a custom discount percentage (0 - 100%):',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),

            // Quick preset chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: quickPresets.map((preset) {
                final isSelected = (_selectedPercent == preset);
                final label = preset == 0 ? 'None (0%)' : '${preset.toStringAsFixed(0)}%';

                return ChoiceChip(
                  label: Text(label),
                  selected: isSelected,
                  selectedColor: AppColors.primaryContainer,
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                  onSelected: (selected) {
                    if (selected) _setPercent(preset);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Custom Percentage Input
            TextField(
              controller: _controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Custom Percentage',
                suffixText: '%',
                border: OutlineInputBorder(borderRadius: AppDimens.radiusMd),
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              onChanged: (val) {
                final parsed = double.tryParse(val);
                if (parsed != null) {
                  setState(() {
                    _selectedPercent = parsed.clamp(0.0, 100.0);
                  });
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: const RoundedRectangleBorder(borderRadius: AppDimens.radiusMd),
          ),
          onPressed: () {
            Navigator.of(context).pop(_selectedPercent);
          },
          child: const Text('Apply Discount'),
        ),
      ],
    );
  }
}
