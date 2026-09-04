import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/pressable_scale.dart';

class AddExpenseSheet extends StatefulWidget {
  const AddExpenseSheet({super.key});

  @override
  State<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<AddExpenseSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  final _noteController = TextEditingController();
  late String _selectedCategory;
  late String _selectedPaymentMethod;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedCategory = AppConstants.expenseCategories.first;
    _selectedPaymentMethod = AppConstants.paymentMethods.first;
    _selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid expense amount'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final result = {
      'amount': amount,
      'description': _descController.text.trim(),
      'category': _selectedCategory,
      'paymentMethod': _selectedPaymentMethod,
      'date': _selectedDate,
      'note': _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
    };

    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Amount Field
          TextFormField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              labelText: 'Amount (₹)',
              prefixIcon: Icon(LucideIcons.indianRupee, color: AppColors.primary, size: 22),
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter amount' : null,
          ),
          const SizedBox(height: 16),

          // Description
          TextFormField(
            controller: _descController,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'e.g. Lunch with team, Groceries',
              prefixIcon: Icon(LucideIcons.fileText, color: AppColors.textMuted, size: 20),
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter description' : null,
          ),
          const SizedBox(height: 16),

          // Category & Payment Method
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  dropdownColor: AppColors.card,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  items: AppConstants.expenseCategories.map((c) {
                    final label = c[0].toUpperCase() + c.substring(1);
                    return DropdownMenuItem(value: c, child: Text(label));
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedCategory = v);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedPaymentMethod,
                  dropdownColor: AppColors.card,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Payment',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  items: AppConstants.paymentMethods.map((m) {
                    final label = m.replaceAll('_', ' ').toUpperCase();
                    return DropdownMenuItem(value: m, child: Text(label));
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedPaymentMethod = v);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Date Picker Tile
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
                        surface: AppColors.card,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) setState(() => _selectedDate = picked);
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.calendar, color: AppColors.textMuted, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        'Date: ${DateFormat('MMMM d, yyyy').format(_selectedDate)}',
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                      ),
                    ],
                  ),
                  const Icon(LucideIcons.chevronDown, color: AppColors.textMuted, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Note (Optional)
          TextFormField(
            controller: _noteController,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Additional Note (Optional)',
              prefixIcon: Icon(LucideIcons.stickyNote, color: AppColors.textMuted, size: 20),
            ),
          ),
          const SizedBox(height: 24),

          // Submit
          PressableScale(
            onTap: _submit,
            child: Container(
              height: 50,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Text(
                  'Add Expense',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
