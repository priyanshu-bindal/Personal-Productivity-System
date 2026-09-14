import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/ocean_theme.dart';
import '../../core/widgets/premium_dropdown_field.dart';
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
  final _nameFocusNode = FocusNode();
  late String _selectedCategory;
  late String _selectedLevel;
  late int _sessionDuration;
  late Set<String> _selectedDays;
  // Pre-built once in initState — never rebuilt on every build() call.
  late final List<PremiumDropdownItem<String>> _categoryItems;
  late final List<PremiumDropdownItem<String>> _levelItems;
  bool _isSubmitting = false;
  bool _isNameFocused = false;

  // Per-day animation controllers for scale animation
  final Map<String, AnimationController> _dayControllers = {};
  final Map<String, Animation<double>> _dayScales = {};

  static const List<String> weekDays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  String _safeCategory(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return AppConstants.skillCategories.first;
    }
    final normalized = raw.trim();
    final uniqueCategories = AppConstants.skillCategories.toSet().toList();
    if (uniqueCategories.contains(normalized)) return normalized;
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

  static IconData _getCategoryIcon(String cat) {
    switch (cat.toLowerCase()) {
      case 'programming':
        return LucideIcons.code;
      case 'design':
        return LucideIcons.palette;
      case 'language':
        return LucideIcons.languages;
      case 'music':
        return LucideIcons.music;
      case 'fitness':
        return LucideIcons.activity;
      case 'business':
        return LucideIcons.briefcase;
      case 'career':
        return LucideIcons.trendingUp;
      default:
        return LucideIcons.layers;
    }
  }

  static Color _getCategoryColor(String cat) {
    switch (cat.toLowerCase()) {
      case 'programming':
        return AppColors.primary;
      case 'design':
        return const Color(0xFFEC4899);
      case 'language':
        return const Color(0xFF06B6D4);
      case 'music':
        return const Color(0xFFA855F7);
      case 'fitness':
        return const Color(0xFF10B981);
      case 'business':
        return AppColors.accentAmber;
      case 'career':
        return const Color(0xFF3B82F6);
      default:
        return AppColors.textSecondary;
    }
  }

  static IconData _getLevelIcon(String level) {
    switch (level.toLowerCase()) {
      case 'beginner':
        return LucideIcons.signalLow;
      case 'intermediate':
        return LucideIcons.signalMedium;
      case 'advanced':
        return LucideIcons.signalHigh;
      case 'expert':
        return LucideIcons.zap;
      default:
        return LucideIcons.award;
    }
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

    // Build item lists once — avoids recreating them on every build() call.
    final categories = AppConstants.skillCategories.toSet().toList();
    _categoryItems = categories
        .map((c) => PremiumDropdownItem<String>(
              value: c,
              label: c,
              icon: _getCategoryIcon(c),
              iconColor: _getCategoryColor(c),
            ))
        .toList();
    _levelItems = AppConstants.skillLevels
        .map((l) => PremiumDropdownItem<String>(
              value: l,
              label: l,
              icon: _getLevelIcon(l),
              iconColor: AppColors.primary,
            ))
        .toList();

    _nameFocusNode.addListener(() {
      if (mounted) {
        setState(() {
          _isNameFocused = _nameFocusNode.hasFocus;
        });
      }
    });

    for (final day in weekDays) {
      final ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 200),
      );
      _dayControllers[day] = ctrl;
      _dayScales[day] = Tween<double>(begin: 0.96, end: 1.0).animate(
        CurvedAnimation(parent: ctrl, curve: Curves.easeOutCubic),
      );
      ctrl.value = 1.0;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
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
    ctrl.reverse().then((_) {
      if (mounted) ctrl.forward();
    });
  }

  void _submit() {
    if (_isSubmitting) return;
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

    setState(() => _isSubmitting = true);

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
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Skill Name Input Field
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: _isNameFocused
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: TextFormField(
                controller: _nameController,
                focusNode: _nameFocusNode,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                decoration: InputDecoration(
                  labelText: 'Skill Name',
                  hintText: 'e.g. System Design, Python, Flutter',
                  hintStyle: const TextStyle(color: AppColors.textFaint, fontSize: 13),
                  prefixIcon: Icon(
                    LucideIcons.code,
                    color: _isNameFocused ? AppColors.primary : AppColors.textDim,
                    size: 19,
                  ),
                  filled: true,
                  fillColor: _isNameFocused
                      ? OceanTheme.cardHi.withValues(alpha: 0.9)
                      : OceanTheme.bg.withValues(alpha: 0.45),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.8),
                      width: 1.4,
                    ),
                  ),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Please enter skill name' : null,
              ),
            ),
            const SizedBox(height: 16),

            // Category & Level Dropdowns
            Row(
              children: [
                Expanded(
                  child: PremiumDropdownField<String>(
                    label: 'Category',
                    value: _selectedCategory,
                    items: _categoryItems,
                    onChanged: (val) {
                      setState(() => _selectedCategory = val);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PremiumDropdownField<String>(
                    label: 'Level',
                    value: _selectedLevel,
                    items: _levelItems,
                    onChanged: (val) {
                      setState(() => _selectedLevel = val);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Target Session Duration
            const Text(
              'Target Session Duration',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [30, 45, 60, 90, 120].map((duration) {
                  final isSelected = _sessionDuration == duration;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text('$duration mins'),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      backgroundColor: OceanTheme.card,
                      checkmarkColor: OceanTheme.bg,
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                      labelStyle: TextStyle(
                        color: isSelected ? OceanTheme.bg : AppColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
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
                    fontSize: 13,
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
                      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? const LinearGradient(
                                colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: isSelected ? null : OceanTheme.card,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0x733B82F6)
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
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 26),

            // Submit Button
            PressableScale(
              onTap: _isSubmitting ? null : _submit,
              child: Container(
                height: 50,
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
                      : Text(
                          widget.existingSkillId != null
                              ? 'Update Skill'
                              : 'Create Skill',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
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
