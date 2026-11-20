import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/pressable_scale.dart';
import '../../models/expense.dart';
import 'widgets/financial_dropdown_field.dart';
import 'widgets/transaction_list_item.dart';

class AddExpenseSheet extends StatefulWidget {
  final String? initialCategory;
  final Expense? existingExpense;

  const AddExpenseSheet({
    super.key,
    this.initialCategory,
    this.existingExpense,
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
  final _descFocusNode = FocusNode();
  final _noteFocusNode = FocusNode();

  late String _selectedCategory;
  late String _selectedPaymentMethod;
  late DateTime _selectedDate;

  bool _isSubmitting = false;
  bool _isAmountFocused = false;
  bool _isDescFocused = false;
  bool _isNoteFocused = false;
  bool _hasRequestedFocus = false;

  final List<double> _quickAmounts = [100, 250, 500, 1000, 2000];

  // Design Tokens (Refined Dark Palette - No Bright Glow)
  static const Color _surfaceCard = Color(0xFF16161B);
  static const Color _borderColor = Color(0xFF26262C);
  static const Color _borderActive = Color(0xFF3B82F6);
  static const Color _textPrimary = Color(0xFFF4F4F5);
  static const Color _textSecondary = Color(0xFFA1A1AA);
  static const Color _textMuted = Color(0xFF71717A);
  static const Color _accent = Color(0xFF3B82F6);

  @override
  void initState() {
    super.initState();
    final exp = widget.existingExpense;
    if (exp != null) {
      final amtStr = exp.amount.truncateToDouble() == exp.amount
          ? exp.amount.toInt().toString()
          : exp.amount.toString();
      _amountController.text = amtStr;
      _descController.text = exp.description;
      _noteController.text = exp.note ?? '';
      _selectedCategory = exp.category.toLowerCase();
      _selectedPaymentMethod =
          exp.paymentMethod.toLowerCase().replaceAll(' ', '_');
      _selectedDate = DateTime.tryParse(exp.expenseDate) ?? DateTime.now();
    } else {
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
    }

    _amountFocusNode.addListener(_handleAmountFocusChange);
    _descFocusNode.addListener(() {
      if (mounted) setState(() => _isDescFocused = _descFocusNode.hasFocus);
    });
    _noteFocusNode.addListener(() {
      if (mounted) setState(() => _isNoteFocused = _noteFocusNode.hasFocus);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_hasRequestedFocus) {
        _hasRequestedFocus = true;
        _amountFocusNode.requestFocus();
      }
    });
  }

  void _handleAmountFocusChange() {
    if (mounted && !_isSubmitting) {
      if (_isAmountFocused != _amountFocusNode.hasFocus) {
        setState(() {
          _isAmountFocused = _amountFocusNode.hasFocus;
        });
      }
    }
  }

  @override
  void dispose() {
    _amountFocusNode.removeListener(_handleAmountFocusChange);
    _amountController.dispose();
    _descController.dispose();
    _noteController.dispose();
    _amountFocusNode.dispose();
    _descFocusNode.dispose();
    _noteFocusNode.dispose();
    super.dispose();
  }

  void _addQuickAmount(double val) {
    HapticFeedback.selectionClick();
    final current = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final total = (current + val).toStringAsFixed(0);
    _amountController.text = total;
    _amountController.selection = TextSelection.fromPosition(
      TextPosition(offset: _amountController.text.length),
    );
    setState(() {});
  }

  void _clearAmount() {
    HapticFeedback.lightImpact();
    _amountController.clear();
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

  String _formatQuickAmount(double val) {
    if (val >= 1000) {
      final k = val / 1000;
      return k == k.roundToDouble()
          ? '+₹${k.toInt()}k'
          : '+₹${k.toStringAsFixed(1)}k';
    }
    return '+₹${val.toInt()}';
  }

  void _submit() {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Amount must be greater than ₹0.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
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

    _amountFocusNode.unfocus();
    FocusScope.of(context).unfocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final categoryItems = AppConstants.expenseCategories.map((c) {
      final label = c[0].toUpperCase() + c.substring(1);
      final icon = TransactionListItem.getCategoryIcon(c);
      return FinancialDropdownItem<String>(
        value: c,
        label: label,
        icon: icon,
        iconColor: _textSecondary,
      );
    }).toList();

    final paymentItems = AppConstants.paymentMethods.map((m) {
      return FinancialDropdownItem<String>(
        value: m,
        label: _getPaymentLabel(m),
        icon: _getPaymentIcon(m),
        iconColor: _textSecondary,
      );
    }).toList();

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── 1. Hero Amount Card ──────────────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: _surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isAmountFocused ? _borderActive : _borderColor,
                width: _isAmountFocused ? 1.2 : 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'AMOUNT',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.9,
                        color: _textMuted,
                      ),
                    ),
                    if (_amountController.text.isNotEmpty)
                      GestureDetector(
                        onTap: _clearAmount,
                        behavior: HitTestBehavior.opaque,
                        child: const Padding(
                          padding: EdgeInsets.all(2.0),
                          child: Row(
                            children: [
                              Icon(
                                LucideIcons.x,
                                size: 13,
                                color: _textMuted,
                              ),
                              SizedBox(width: 3),
                              Text(
                                'Clear',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: _textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '₹ ',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w600,
                        color: _isAmountFocused ? _accent : _textMuted,
                      ),
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: _amountController,
                        focusNode: _amountFocusNode,
                        autofocus: false,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(
                          color: _textPrimary,
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                        cursorColor: _accent,
                        decoration: const InputDecoration(
                          hintText: '0',
                          hintStyle: TextStyle(
                            color: Color(0xFF3F3F46),
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
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
              ],
            ),
          ),
          const SizedBox(height: 10),

          // ── 2. Quick Amount Selector Pills ───────────────────────────
          Row(
            children: _quickAmounts.map((amt) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.5),
                  child: PressableScale(
                    onTap: () => _addQuickAmount(amt),
                    scaleFactor: 0.94,
                    child: Container(
                      height: 33,
                      decoration: BoxDecoration(
                        color: _surfaceCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _borderColor, width: 1.0),
                      ),
                      child: Center(
                        child: Text(
                          _formatQuickAmount(amt),
                          style: const TextStyle(
                            color: _textSecondary,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          // ── 3. Description Input Card ────────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: _surfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isDescFocused ? _borderActive : _borderColor,
                width: _isDescFocused ? 1.2 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.fileText,
                  size: 16,
                  color: _isDescFocused ? _accent : _textMuted,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _descController,
                    focusNode: _descFocusNode,
                    textCapitalization: TextCapitalization.sentences,
                    style: const TextStyle(
                      color: _textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    cursorColor: _accent,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      labelStyle: TextStyle(
                        color: _textMuted,
                        fontSize: 13,
                      ),
                      hintText: 'What was this for? (e.g. Lunch, Uber)',
                      hintStyle: TextStyle(
                        color: Color(0xFF52525B),
                        fontSize: 13,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      floatingLabelBehavior: FloatingLabelBehavior.auto,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // ── 4. Category & Payment Dropdown Row ───────────────────────
          Row(
            children: [
              Expanded(
                child: FinancialDropdownField<String>(
                  label: 'Category',
                  value: _selectedCategory,
                  items: categoryItems,
                  onChanged: (val) {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedCategory = val);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FinancialDropdownField<String>(
                  label: 'Payment',
                  value: _selectedPaymentMethod,
                  items: paymentItems,
                  onChanged: (val) {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedPaymentMethod = val);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── 5. Date & Note Row ───────────────────────────────────────
          Row(
            children: [
              // Date Selector
              Expanded(
                flex: 4,
                child: PressableScale(
                  onTap: () async {
                    HapticFeedback.selectionClick();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      builder: (context, child) {
                        return Theme(
                          data: ThemeData.dark().copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: _accent,
                              surface: _surfaceCard,
                              onSurface: _textPrimary,
                            ),
                            dialogTheme: const DialogThemeData(
                              backgroundColor: Color(0xFF16161B),
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      setState(() => _selectedDate = picked);
                    }
                  },
                  scaleFactor: 0.97,
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: _surfaceCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _borderColor, width: 1.0),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          LucideIcons.calendar,
                          color: _textMuted,
                          size: 15,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            DateFormat('MMM d, yyyy').format(_selectedDate),
                            style: const TextStyle(
                              color: _textPrimary,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(
                          LucideIcons.chevronDown,
                          color: _textMuted,
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Note Input (Optional)
              Expanded(
                flex: 5,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: _surfaceCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isNoteFocused ? _borderActive : _borderColor,
                      width: _isNoteFocused ? 1.2 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.stickyNote,
                        color: _isNoteFocused ? _accent : _textMuted,
                        size: 15,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _noteController,
                          focusNode: _noteFocusNode,
                          textCapitalization: TextCapitalization.sentences,
                          style: const TextStyle(
                            color: _textPrimary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                          cursorColor: _accent,
                          decoration: const InputDecoration(
                            hintText: 'Note (Optional)',
                            hintStyle: TextStyle(
                              color: Color(0xFF52525B),
                              fontSize: 12.5,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            focusedErrorBorder: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),

          // ── 6. Primary Action CTA Button ─────────────────────────────
          PressableScale(
            onTap: _isSubmitting ? null : _submit,
            scaleFactor: 0.98,
            child: Container(
              height: 48,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: _accent,
              ),
              child: Center(
                child: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.0,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.existingExpense != null
                                ? LucideIcons.check
                                : LucideIcons.plus,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.existingExpense != null
                                ? 'Save Changes'
                                : 'Add Expense',
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
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
    );
  }
}
