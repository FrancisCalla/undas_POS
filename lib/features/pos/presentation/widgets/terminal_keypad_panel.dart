import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../providers/cart_provider.dart';

/// Right-hand control panel:
/// - 2 Action Buttons: CLEAR ITEM, CLEAR ORDER
/// - Visual Keypad Quantity Buffer Readout
/// - 4x3 Touch Numeric Keypad
class TerminalKeypadPanel extends ConsumerStatefulWidget {
  const TerminalKeypadPanel({super.key});

  @override
  ConsumerState<TerminalKeypadPanel> createState() => _TerminalKeypadPanelState();
}

class _TerminalKeypadPanelState extends ConsumerState<TerminalKeypadPanel> {
  String _keypadBuffer = '';

  void _handleKeypadInput(String digit) {
    final cartState = ref.read(cartNotifierProvider);
    if (cartState.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select or add a product first to adjust quantity.'),
          duration: Duration(milliseconds: 900),
          backgroundColor: AppColors.posOrange,
        ),
      );
      return;
    }

    final selectedId = ref.read(selectedCartItemIdProvider) ??
        cartState.items.last.product.id;

    setState(() {
      if (digit == 'C' || digit == '.') {
        _keypadBuffer = '';
        return;
      }

      if (digit == '00') {
        if (_keypadBuffer.isEmpty) return;
        _keypadBuffer += '00';
      } else {
        // Append digit (up to 3 digits for practical retail quantities)
        if (_keypadBuffer.length >= 3) {
          _keypadBuffer = digit;
        } else {
          _keypadBuffer += digit;
        }
      }
    });

    final newQty = int.tryParse(_keypadBuffer);
    if (newQty != null && newQty > 0) {
      final res = ref.read(cartNotifierProvider.notifier).setQuantity(selectedId, newQty);
      if (res == AddToCartResult.exceedsAvailableStock && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Entered quantity exceeds available stock!'),
            backgroundColor: AppColors.posOrange,
            duration: Duration(seconds: 1),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartNotifierProvider);
    final selectedItemId = ref.watch(selectedCartItemIdProvider);

    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(4),
      child: Column(
        children: [
          // 2 ACTION BUTTONS: CLEAR ITEM | CLEAR ORDER
          SizedBox(
            height: 52,
            child: Row(
              children: [
                // CLEAR ITEM - removes the currently selected line
                Expanded(
                  child: _FuncButton(
                    label: 'CLEAR ITEM',
                    color: AppColors.posDarkRed,
                    textColor: Colors.white,
                    onTap: cartState.items.isEmpty
                        ? null
                        : () {
                            final targetId =
                                selectedItemId ?? cartState.items.last.product.id;
                            ref
                                .read(cartNotifierProvider.notifier)
                                .removeItem(targetId);
                            setState(() => _keypadBuffer = '');
                          },
                  ),
                ),
                const SizedBox(width: 4),
                // CLEAR ORDER - voids entire ticket after confirmation
                Expanded(
                  child: _FuncButton(
                    label: 'CLEAR ORDER',
                    color: AppColors.posRed,
                    textColor: Colors.white,
                    onTap: cartState.isEmpty
                        ? null
                        : () => _confirmClear(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // KEYPAD BUFFER / STATUS READOUT BAR
          Container(
            height: 26,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF161616),
              border: Border.all(color: const Color(0xFF333333)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'QTY KEYPAD:',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF888888),
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  _keypadBuffer.isEmpty ? 'TAP DIGITS TO SET' : '$_keypadBuffer units',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: _keypadBuffer.isEmpty
                        ? const Color(0xFF666666)
                        : AppColors.posLimeGreen,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // 4x3 NUMERIC KEYPAD
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      _KeypadButton(digit: '7', onTap: () => _handleKeypadInput('7')),
                      const SizedBox(width: 4),
                      _KeypadButton(digit: '8', onTap: () => _handleKeypadInput('8')),
                      const SizedBox(width: 4),
                      _KeypadButton(digit: '9', onTap: () => _handleKeypadInput('9')),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: Row(
                    children: [
                      _KeypadButton(digit: '4', onTap: () => _handleKeypadInput('4')),
                      const SizedBox(width: 4),
                      _KeypadButton(digit: '5', onTap: () => _handleKeypadInput('5')),
                      const SizedBox(width: 4),
                      _KeypadButton(digit: '6', onTap: () => _handleKeypadInput('6')),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: Row(
                    children: [
                      _KeypadButton(digit: '1', onTap: () => _handleKeypadInput('1')),
                      const SizedBox(width: 4),
                      _KeypadButton(digit: '2', onTap: () => _handleKeypadInput('2')),
                      const SizedBox(width: 4),
                      _KeypadButton(digit: '3', onTap: () => _handleKeypadInput('3')),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: Row(
                    children: [
                      _KeypadButton(digit: '0', onTap: () => _handleKeypadInput('0')),
                      const SizedBox(width: 4),
                      _KeypadButton(digit: 'C', onTap: () => _handleKeypadInput('C')),
                      const SizedBox(width: 4),
                      _KeypadButton(digit: '00', onTap: () => _handleKeypadInput('00')),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmClear(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Entire Order?'),
        content: const Text(
            'This will void and remove all items from the current ticket.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.posRed),
            onPressed: () {
              ref.read(cartNotifierProvider.notifier).clearCart();
              setState(() => _keypadBuffer = '');
              Navigator.of(ctx).pop();
            },
            child: const Text('Clear Order'),
          ),
        ],
      ),
    );
  }
}

class _FuncButton extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback? onTap;

  const _FuncButton({
    required this.label,
    required this.color,
    required this.textColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: onTap != null ? color : color.withValues(alpha: 0.35),
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
              color: onTap != null ? textColor : textColor.withValues(alpha: 0.4),
            ),
          ),
        ),
      ),
    );
  }
}

class _KeypadButton extends StatelessWidget {
  final String digit;
  final VoidCallback onTap;

  const _KeypadButton({required this.digit, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: digit == 'C' ? const Color(0xFF3A3A3A) : AppColors.posKeypadBg,
        child: InkWell(
          onTap: onTap,
          splashColor: AppColors.posKeypadPressed,
          child: Center(
            child: Text(
              digit,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: digit == 'C' ? AppColors.posOrange : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
