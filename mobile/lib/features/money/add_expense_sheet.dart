import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/ocean_theme.dart';
import 'widgets/financial_dropdown_field.dart';
import 'widgets/transaction_list_item.dart';

class AddExpenseSheet extends StatefulWidget {
  final String? initialCategory;

  const AddExpenseSheet({
    super.key,
    this.initialCategory,
  });

  @override
  State<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<AddExpenseSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  final _noteController = TextEditingController();
  final _amountFocusNode = FocusNode();

  late String _selectedCategory;
  late String _selectedPaymentMethod;
  late DateTime _selectedDate;

  bool _isSubmitting = false;
  bool _isAmountFocused = false;

  final List<double> _quickAmounts = [100, 250, 500, 1000, 2000];

  @override
  void initState() {
    super.initState();
    final initCat = widget.initialCategory?.trim().toLowerCase();
    if (initCat != null &&
        AppConstants.expenseCategories
            .any((c) => c.toLowerCase() == initCat)) {
      _selectedCategory = initCat;
    } else {
      _selectedCategory = AppConstants.expenseCategories.first;
    }
    _selectedPaymentMethod = AppConstants.paymentMethods.first;
    _selectedDate = DateTime.now();

    _amountFocusNode.addListener(() {
      if (mounted) {
        setState(() {
          _isAmountFocused = _amountFocusNode.hasFocus;
        });
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    _noteController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  void _addQuickAmount(double val) {
    final current = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final total = (current + val).toStringAsFixed(0);
    _amountController.text = total;
    _amountController.selection = TextSelection.fromPosition(
      TextPosition(offset: _amountController.text.length),
    );
    setState(() {});
  }

  static IconData _getPaymentIcon(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return Icons.payments_outlined;
      case 'upi':
        return Icons.qr_code_2_rounded;
      case 'debit_card':
        return Icons.credit_card_outlined;
      case 'credit_card':
        return Icons.credit_card;
      case 'bank_transfer':
        return Icons.account_balance_outlined;
      default:
        return Icons.more_horiz;
    }
  }

  static String _getPaymentLabel(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return 'CASH';
      case 'upi':
        return 'UPI';
      case 'debit_card':
        return 'DEBIT CARD';
      case 'credit_card':
        return 'CREDIT CARD';
      case 'bank_transfer':
        return 'BANK TRANSFER';
      default:
        return 'OTHER';
    }
  }

  void _submit() {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Amount must be greater than ₹0.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final desc = _descController.text.trim().isNotEmpty
        ? _descController.text.trim()
        : '${_selectedCategory[0].toUpperCase()}${_selectedCategory.substring(1)} expense';

    final result = {
      'amount': amount,
      'description': desc,
      'category': _selectedCategory,
      'paymentMethod': _selectedPaymentMethod,
      'date': _selectedDate,
      'note': _noteController.text.trim().isNotEmpty
          ? _noteController.text.trim()
          : null,
    };

    // Instant pop without any artificial delays!
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    // Build category items
    final categoryItems = AppConstants.expenseCategories.map((c) {
      final label = c[0].toUpperCase() + c.substring(1);
      final icon = TransactionListItem.getCategoryIcon(c);
      final iconColor = TransactionListItem.getCategoryColor(c);
      return FinancialDropdownItem<String>(
        value: c,
        label: label,
        icon: icon,
        iconColor: iconColor,
      );
    }).toList();

    // Build payment items
    final paymentItems = AppConstants.paymentMethods.map((m) {
      return FinancialDropdownItem<String>(
        value: m,
        label: _getPaymentLabel(m),
        icon: _getPaymentIcon(m),
        iconColor: AppColors.secondary,
      );
    }).toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // UNIFIED AMOUNT INPUT COMPONENT (Single clean border with smooth focus animation)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: _isAmountFocused
                    ? OceanTheme.cardHi.withValues(alpha: 0.85)
                    : OceanTheme.card.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isAmountFocused
                      ? AppColors.secondary.withValues(alpha: 0.8)
                      : AppColors.border,
                  width: _isAmountFocused ? 1.4 : 1.0,
                ),
                boxShadow: _isAmountFocused
                    ? [
                        BoxShadow(
                          color: AppColors.secondary.withValues(alpha: 0.14),
                          blurRadius: 14,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : const [
                        BoxShadow(
                          color: Color(0x20000000),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AMOUNT',
                    style: TextStyle(
                      color: AppColors.textDim,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '₹ ',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: _isAmountFocused
                              ? AppColors.blueHighlight
                              : AppColors.secondary,
                        ),
                      ),
                      Expanded(
                        child: TextFormField(
                          controller: _amountController,
                          focusNode: _amountFocusNode,
                          autofocus: true,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                          decoration: const InputDecoration(
                            hintText: '0',
                            hintStyle: TextStyle(
                              color: AppColors.textFaint,
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            focusedErrorBorder: InputBorder.none,
                            filled: false,
                            fillColor: Colors.transparent,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Enter an amount.';
                            }
                            final parsed = double.tryParse(v.trim());
                            if (parsed == null) {
                              return 'Enter a valid amount.';
                            }
                            if (parsed <= 0) {
                              return 'Amount must be greater than ₹0.';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 1,
                    color: _isAmountFocused
                        ? AppColors.secondary.withValues(alpha: 0.35)
                        : AppColors.border.withValues(alpha: 0.6),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Quick Amount Selector Chips
            SizedBox(
              height: 32,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _quickAmounts.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final amt = _quickAmounts[index];
                  return InkWell(
                    onTap: () => _addQuickAmount(amt),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: OceanTheme.cardHi,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Center(
                        child: Text(
                          '+₹${amt.toInt()}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Description Input
            TextFormField(
              controller: _descController,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              inputFormatters: [_TitleCaseFormatter()],
              decoration: InputDecoration(
                labelText: 'Description',
                hintText: 'e.g. Groceries, Team Lunch, Books',
                hintStyle: const TextStyle(color: AppColors.textFaint, fontSize: 13),
                prefixIcon: const Icon(LucideIcons.fileText, color: AppColors.textDim, size: 18),
                filled: true,
                fillColor: OceanTheme.bg.withValues(alpha: 0.35),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.8)),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Premium Custom Dropdown Row: Category & Payment
            Row(
              children: [
                Expanded(
                  child: FinancialDropdownField<String>(
                    label: 'Category',
                    value: _selectedCategory,
                    items: categoryItems,
                    onChanged: (val) {
                      setState(() => _selectedCategory = val);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FinancialDropdownField<String>(
                    label: 'Payment',
                    value: _selectedPaymentMethod,
                    items: paymentItems,
                    onChanged: (val) {
                      setState(() => _selectedPaymentMethod = val);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Date Selector
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  builder: (context, child) {
                    return Theme(
                      data: ThemeData.dark().copyWith(
                        colorScheme: const ColorScheme.dark(
                          primary: AppColors.primary,
                          surface: OceanTheme.card,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) setState(() => _selectedDate = picked);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: OceanTheme.bg.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.calendar, color: AppColors.textDim, size: 16),
                        const SizedBox(width: 10),
                        Text(
                          DateFormat('MMMM d, yyyy').format(_selectedDate),
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                        ),
                      ],
                    ),
                    const Icon(LucideIcons.chevronDown, color: AppColors.textDim, size: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Note Field (Optional)
            TextFormField(
              controller: _noteController,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Note (Optional)',
                hintText: 'Add context or tags',
                hintStyle: const TextStyle(color: AppColors.textFaint, fontSize: 13),
                prefixIcon: const Icon(LucideIcons.stickyNote, color: AppColors.textDim, size: 18),
                filled: true,
                fillColor: OceanTheme.bg.withValues(alpha: 0.35),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.8)),
                ),
              ),
            ),
            const SizedBox(height: 22),

            // Premium Financial CTA Button
            InkWell(
              onTap: _isSubmitting ? null : _submit,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                height: 52,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF14C8A8),
                      Color(0xFF0F9F86),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.28),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(LucideIcons.plusCircle, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Add Expense',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Capitalises the first letter of every word while the user types.
///
/// Rules:
/// - The very first character is always uppercased.
/// - The character immediately after a space is uppercased.
/// - All other characters are left exactly as typed (no forced lowercase).
/// - Cursor position and selection are preserved through the transformation.
class _TitleCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;

    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      final ch = text[i];
      // Capitalise if this is the very first character, or if the preceding
      // character is a space (i.e. we are at the start of a new word).
      final shouldCapitalise = i == 0 || text[i - 1] == ' ';
      buffer.write(shouldCapitalise ? ch.toUpperCase() : ch);
    }

    final formatted = buffer.toString();

    // If nothing changed, return the new value untouched to avoid a
    // pointless rebuild that would reset the IME composing region.
    if (formatted == text) return newValue;

    // Clamp the selection/composing extents to the (same-length) new string.
    return newValue.copyWith(
      text: formatted,
      selection: newValue.selection.copyWith(
        baseOffset: newValue.selection.baseOffset.clamp(0, formatted.length),
        extentOffset:
            newValue.selection.extentOffset.clamp(0, formatted.length),
      ),
    );
  }
}
