import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/pressable_scale.dart';

class AddSkillSheet extends ConsumerStatefulWidget {
  final String? existingSkillId;
  final String? initialName;
  final String? initialCategory;
  final String? initialLevel;
  final int? initialDuration;
  final List<String>? initialDays;

  const AddSkillSheet({
    super.key,
    this.existingSkillId,
    this.initialName,
    this.initialCategory,
    this.initialLevel,
    this.initialDuration,
    this.initialDays,
  });

  @override
  ConsumerState<AddSkillSheet> createState() => _AddSkillSheetState();
}

class _AddSkillSheetState extends ConsumerState<AddSkillSheet>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late String _selectedCategory;
  late String _selectedLevel;
  late int _sessionDuration;
  late Set<String> _selectedDays;

  // Per-day animation controllers for scale animation
  final Map<String, AnimationController> _dayControllers = {};
  final Map<String, Animation<double>> _dayScales = {};

  static const List<String> weekDays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  /// Safely resolve a category value against the available list.
  /// Falls back to the first item if the value is null/empty or not in list.
  String _safeCategory(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return AppConstants.skillCategories.first;
    }
    // Try exact match first
    final normalized = raw.trim();
    final uniqueCategories = AppConstants.skillCategories.toSet().toList();
    if (uniqueCategories.contains(normalized)) return normalized;
    // Case-insensitive fallback
    final lower = normalized.toLowerCase();
    try {
      return uniqueCategories.firstWhere(
        (c) => c.toLowerCase() == lower,
        orElse: () => AppConstants.skillCategories.first,
      );
    } catch (_) {
      return AppConstants.skillCategories.first;
    }
  }

  String _safeLevel(String? raw) {
    if (raw == null || raw.trim().isEmpty) return AppConstants.skillLevels.first;
    final normalized = raw.trim();
    if (AppConstants.skillLevels.contains(normalized)) return normalized;
    return AppConstants.skillLevels.first;
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _selectedCategory = _safeCategory(widget.initialCategory);
    _selectedLevel = _safeLevel(widget.initialLevel);
    _sessionDuration = widget.initialDuration ?? 60;
    _selectedDays = Set<String>.from(
      widget.initialDays ?? ['Monday', 'Wednesday', 'Friday'],
    );

    // Create one animation controller per day chip
    for (final day in weekDays) {
      final ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 200),
      );
      _dayControllers[day] = ctrl;
      _dayScales[day] = Tween<double>(begin: 0.96, end: 1.0).animate(
        CurvedAnimation(parent: ctrl, curve: Curves.easeOutCubic),
      );
      // Start fully scaled in
      ctrl.value = 1.0;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final ctrl in _dayControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  void _toggleDay(String day) {
    final ctrl = _dayControllers[day]!;
    setState(() {
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
      }
    });
    // Brief scale-out then scale-in for tactile feedback
    ctrl.reverse().then((_) => ctrl.forward());
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least 1 practice day per week'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final result = {
      'name': _nameController.text.trim(),
      'category': _selectedCategory,
      'level': _selectedLevel,
      'sessionDuration': _sessionDuration,
      'preferredDays': _selectedDays.toList(),
    };

    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    // Deduplicated, ordered category list
    final categories = AppConstants.skillCategories.toSet().toList();

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Skill Name
          TextFormField(
            controller: _nameController,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Skill Name',
              hintText: 'e.g. System Design, Python, Flutter',
              prefixIcon: Icon(LucideIcons.code, color: AppColors.textMuted, size: 20),
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter skill name' : null,
          ),
          const SizedBox(height: 16),

          // Category Dropdown & Level Dropdown
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
                  items: categories.map((c) {
                    return DropdownMenuItem(value: c, child: Text(c));
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedCategory = v);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedLevel,
                  dropdownColor: AppColors.card,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Level',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  items: AppConstants.skillLevels.map((l) {
                    return DropdownMenuItem(value: l, child: Text(l));
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedLevel = v);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Session Duration Picker
          const Text(
            'Target Session Duration',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [30, 45, 60, 90, 120].map((duration) {
                final isSelected = _sessionDuration == duration;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text('$duration mins'),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.surface,
                    checkmarkColor: Colors.white,
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.border,
                    ),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    onSelected: (selected) {
                      if (selected) setState(() => _sessionDuration = duration);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // Preferred Practice Days
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Preferred Practice Days',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${_selectedDays.length} days / week',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: weekDays.map((day) {
              final isSelected = _selectedDays.contains(day);
              return ScaleTransition(
                scale: _dayScales[day]!,
                child: GestureDetector(
                  onTap: () => _toggleDay(day),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      // Premium sapphire-blue gradient when selected
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isSelected ? null : AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0x733B82F6) // rgba(59,130,246,0.45)
                            : AppColors.border,
                        width: isSelected ? 1.2 : 1.0,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF3B82F6).withValues(alpha: 0.22),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected) ...[
                          const Icon(
                            LucideIcons.check,
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          day.substring(0, 3),
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondary,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),

          // Submit Button
          PressableScale(
            onTap: _submit,
            child: Container(
              height: 50,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.cardHi,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.45),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.18),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  widget.existingSkillId != null ? 'Update Skill' : 'Create Skill',
                  style: const TextStyle(
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
