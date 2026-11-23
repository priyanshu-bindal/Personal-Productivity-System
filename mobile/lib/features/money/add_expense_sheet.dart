import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/oled_theme.dart';
import '../../models/expense.dart';
import 'widgets/financial_dropdown_field.dart';
import 'widgets/transaction_list_item.dart';

class AddExpenseSheet extends StatefulWidget {
  const AddExpenseSheet({
    super.key,
    this.initialCategory,
    this.existingExpense,
  });

  final String? initialCategory;
  final Expense? existingExpense;

  @override
  State<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<AddExpenseSheet> {
  static const _accent = OledTheme.accent;
  static const _quickAmounts = [100, 250, 500, 1000, 2000];

  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  final _noteController = TextEditingController();

  late String _selectedCategory;
  late String _selectedPaymentMethod;
  late DateTime _selectedDate;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final expense = widget.existingExpense;
    if (expense != null) {
      _amountController.text = expense.amount.toString();
      _descController.text = expense.description;
      _noteController.text = expense.note ?? '';
      _selectedCategory = expense.category.toLowerCase();
      _selectedPaymentMethod = expense.paymentMethod.toLowerCase().replaceAll(
        ' ',
        '_',
      );
      _selectedDate = DateTime.tryParse(expense.expenseDate) ?? DateTime.now();
    } else {
      final category = widget.initialCategory?.trim().toLowerCase();
      _selectedCategory = AppConstants.expenseCategories.contains(category)
          ? category!
          : AppConstants.expenseCategories.first;
      _selectedPaymentMethod = AppConstants.paymentMethods.first;
      _selectedDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  double? get _amount => double.tryParse(_amountController.text.trim());

  void _addQuickAmount(int amount) {
    HapticFeedback.selectionClick();
    final current = _amount ?? 0;
    final total = (current.isFinite ? current : 0) + amount;
    final value = NumberFormat('0.##', 'en').format(total);
    _amountController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  Future<void> _pickDate() async {
    HapticFeedback.selectionClick();
    FocusScope.of(context).unfocus();
    final firstDate = DateTime(2020);
    final lastDate = DateTime.now().add(const Duration(days: 365));
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: _selectedDate.isBefore(firstDate) ? _selectedDate : firstDate,
      lastDate: _selectedDate.isAfter(lastDate) ? _selectedDate : lastDate,
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: _accent,
            surface: OledTheme.cardElevated,
          ),
        ),
        child: child!,
      ),
    );
    if (mounted && picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _submit() {
    if (_isSubmitting || !_formKey.currentState!.validate()) return;

    HapticFeedback.mediumImpact();
    _isSubmitting = true;
    final description = _descController.text.trim();
    final note = _noteController.text.trim();
    FocusScope.of(context).unfocus();
    Navigator.of(context).pop({
      'amount': _amount!,
      'description': description.isEmpty
          ? '${_categoryLabel(_selectedCategory)} expense'
          : description,
      'category': _selectedCategory,
      'paymentMethod': _selectedPaymentMethod,
      'date': _selectedDate,
      'note': note.isEmpty ? null : note,
    });
  }

  static String _categoryLabel(String category) => category.isEmpty
      ? 'Other'
      : category[0].toUpperCase() + category.substring(1);

  static IconData _paymentIcon(String method) => switch (method) {
    'cash' => Icons.payments_outlined,
    'upi' => Icons.qr_code_2_rounded,
    'debit_card' => Icons.credit_card_outlined,
    'credit_card' => Icons.credit_card,
    'bank_transfer' => Icons.account_balance_outlined,
    _ => Icons.more_horiz,
  };

  static InputDecoration _fieldDecoration(
    String label, {
    String? hint,
  }) => InputDecoration(
    labelText: label,
    hintText: hint,
    labelStyle: const TextStyle(color: OledTheme.textSecondary, fontSize: 13),
    hintStyle: const TextStyle(color: OledTheme.textSecondary, fontSize: 13),
    filled: true,
    fillColor: OledTheme.card,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: OledTheme.borderHighlight),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _accent),
    ),
  );

  @override
  Widget build(BuildContext context) {
    const fieldText = TextStyle(color: OledTheme.textPrimary, fontSize: 14);
    final isEditing = widget.existingExpense != null;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildAmount(),
          const SizedBox(height: 20),
          const Text(
            'Transaction details',
            style: TextStyle(
              color: OledTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _descController,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            style: fieldText,
            cursorColor: _accent,
            decoration: _fieldDecoration('Description', hint: 'e.g. Lunch'),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FinancialDropdownField<String>(
                  label: 'Category',
                  value: _selectedCategory,
                  items: [
                    for (final category in AppConstants.expenseCategories)
                      FinancialDropdownItem(
                        value: category,
                        label: _categoryLabel(category),
                        icon: TransactionListItem.getCategoryIcon(category),
                      ),
                  ],
                  onChanged: (value) =>
                      setState(() => _selectedCategory = value),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FinancialDropdownField<String>(
                  label: 'Payment',
                  value: _selectedPaymentMethod,
                  items: [
                    for (final method in AppConstants.paymentMethods)
                      FinancialDropdownItem(
                        value: method,
                        label: method.replaceAll('_', ' ').toUpperCase(),
                        icon: _paymentIcon(method),
                      ),
                  ],
                  onChanged: (value) =>
                      setState(() => _selectedPaymentMethod = value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Semantics(
                  button: true,
                  child: InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: _fieldDecoration('Date'),
                      child: Text(
                        DateFormat('MMM d, yyyy').format(_selectedDate),
                        style: fieldText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _noteController,
                  textCapitalization: TextCapitalization.sentences,
                  style: fieldText,
                  cursorColor: _accent,
                  decoration: _fieldDecoration('Note (optional)'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _submit,
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 49),
              backgroundColor: _accent,
              foregroundColor: OledTheme.bg,
            ),
            icon: Icon(
              isEditing ? LucideIcons.check : LucideIcons.plus,
              size: 18,
            ),
            label: Text(isEditing ? 'Save Changes' : 'Add Expense'),
          ),
        ],
      ),
    );
  }

  Widget _buildAmount() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF142138),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _accent.withValues(alpha: 0.32)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 18, right: 8),
                  child: Text(
                    '₹',
                    style: TextStyle(
                      color: _accent,
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.next,
                    cursorColor: _accent,
                    style: const TextStyle(
                      color: OledTheme.textPrimary,
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      floatingLabelStyle: TextStyle(
                        color: OledTheme.textPrimary,
                        fontSize: 16,
                      ),
                      hintText: '0.00',
                      hintStyle: TextStyle(color: OledTheme.textSecondary),
                      filled: false,
                      isDense: true,
                      contentPadding: EdgeInsets.only(top: 20),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                    ),
                    validator: (_) {
                      final amount = _amount;
                      return amount == null || !amount.isFinite || amount <= 0
                          ? 'Enter an amount greater than ₹0'
                          : null;
                    },
                  ),
                ),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _amountController,
                  builder: (context, value, _) => IconButton(
                    tooltip: 'Clear amount',
                    color: OledTheme.textSecondary,
                    onPressed: value.text.isEmpty
                        ? null
                        : _amountController.clear,
                    icon: const Icon(LucideIcons.x, size: 17),
                  ),
                ),
              ],
            ),
            const Divider(height: 20, color: Color(0xFF314460)),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final amount in _quickAmounts)
                  OutlinedButton(
                    onPressed: () => _addQuickAmount(amount),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: OledTheme.textPrimary,
                      side: const BorderSide(color: Color(0xFF415676)),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(44, 38),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                    child: Text(
                      amount < 1000 ? '+₹$amount' : '+₹${amount ~/ 1000}k',
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
