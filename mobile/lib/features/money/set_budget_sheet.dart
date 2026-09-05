import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/pressable_scale.dart';

class SetBudgetSheet extends StatefulWidget {
  const SetBudgetSheet({super.key});

  @override
  State<SetBudgetSheet> createState() => _SetBudgetSheetState();
}

class _SetBudgetSheetState extends State<SetBudgetSheet> {
  final _formKey = GlobalKey<FormState>();
  final _limitController = TextEditingController();
  late String _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = AppConstants.expenseCategories.first;
  }

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final limit = double.tryParse(_limitController.text.trim());
    if (limit == null || limit <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid monthly budget limit'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final result = {
      'category': _selectedCategory,
      'monthlyLimit': limit,
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
          DropdownButtonFormField<String>(
            initialValue: _selectedCategory,
            dropdownColor: AppColors.card,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Select Category',
            ),
            items: AppConstants.expenseCategories.map((c) {
              final label = c[0].toUpperCase() + c.substring(1);
              return DropdownMenuItem(value: c, child: Text(label));
            }).toList(),
            onChanged: (v) {
              if (v != null) setState(() => _selectedCategory = v);
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _limitController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              labelText: 'Monthly Budget Limit (₹)',
              hintText: 'e.g. 5000',
              prefixIcon: Icon(LucideIcons.indianRupee, color: AppColors.primary, size: 20),
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter limit' : null,
          ),
          const SizedBox(height: 24),

          PressableScale(
            onTap: _submit,
            child: Container(
              height: 50,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.cardHi,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.5),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'Set Monthly Budget',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
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
