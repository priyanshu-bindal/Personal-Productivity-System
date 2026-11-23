import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/oled_theme.dart';
import '../../core/widgets/premium_dropdown_field.dart';

class AddSkillSheet extends StatefulWidget {
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
  State<AddSkillSheet> createState() => _AddSkillSheetState();
}

class _AddSkillSheetState extends State<AddSkillSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;

  late String _selectedCategory;
  late String _selectedLevel;
  late int _sessionDuration;
  late Set<String> _selectedDays;

  late final List<PremiumDropdownItem<String>> _categoryItems;
  late final List<PremiumDropdownItem<String>> _levelItems;

  bool _isSubmitting = false;

  static const List<String> _weekDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const List<int> _durations = [30, 45, 60, 90, 120];

  static const _accent = OledTheme.violet;

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
    if (raw == null || raw.trim().isEmpty)
      return AppConstants.skillLevels.first;
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

    final categories = AppConstants.skillCategories.toSet().toList();
    _categoryItems = categories
        .map(
          (c) => PremiumDropdownItem<String>(
            value: c,
            label: c,
            icon: _getCategoryIcon(c),
            iconColor: OledTheme.textSecondary,
          ),
        )
        .toList();

    _levelItems = AppConstants.skillLevels
        .map(
          (l) => PremiumDropdownItem<String>(
            value: l,
            label: l,
            icon: _getLevelIcon(l),
            iconColor: OledTheme.textSecondary,
          ),
        )
        .toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _toggleDay(String day) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
      }
    });
  }

  void _submit() {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDays.isEmpty) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least 1 practice day per week'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    _isSubmitting = true;

    final result = {
      'name': _nameController.text.trim(),
      'category': _selectedCategory,
      'level': _selectedLevel,
      'sessionDuration': _sessionDuration,
      'preferredDays': _selectedDays.toList(),
    };

    FocusScope.of(context).unfocus();
    Navigator.of(context).pop(result);
  }

  String _formatDuration(int mins) {
    if (mins >= 60 && mins % 30 == 0) {
      final hrs = mins / 60;
      return hrs == hrs.roundToDouble()
          ? '${hrs.toInt()}h'
          : '${hrs.toStringAsFixed(1)}h';
    }
    return '${mins}m';
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingSkillId != null;
    final weeklyHours = _selectedDays.length * _sessionDuration / 60;
    final durations = {..._durations, ?widget.initialDuration}.toList()..sort();

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            style: const TextStyle(color: OledTheme.textPrimary, fontSize: 16),
            cursorColor: _accent,
            decoration: InputDecoration(
              labelText: 'Skill name',
              hintText: 'e.g. System Design, Guitar, Spanish',
              labelStyle: const TextStyle(color: OledTheme.textSecondary),
              hintStyle: const TextStyle(
                color: OledTheme.textSecondary,
                fontSize: 13,
              ),
              prefixIcon: Icon(
                _getCategoryIcon(_selectedCategory),
                color: _accent,
                size: 18,
              ),
              filled: true,
              fillColor: OledTheme.card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: OledTheme.borderHighlight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _accent),
              ),
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Enter a skill name'
                : null,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: PremiumDropdownField<String>(
                  label: 'Category',
                  value: _selectedCategory,
                  items: _categoryItems,
                  onChanged: (value) {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedCategory = value);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PremiumDropdownField<String>(
                  label: 'Level',
                  value: _selectedLevel,
                  items: _levelItems,
                  onChanged: (value) {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedLevel = value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF211B31),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _accent.withValues(alpha: 0.28)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Practice schedule',
                    style: TextStyle(
                      color: OledTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Session duration', style: _sectionLabel),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 5,
                    runSpacing: 4,
                    children: [
                      for (final duration in durations)
                        ChoiceChip(
                          label: Text(_formatDuration(duration)),
                          selected: _sessionDuration == duration,
                          showCheckmark: false,
                          labelPadding: const EdgeInsets.symmetric(
                            horizontal: 3,
                          ),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          side: BorderSide(
                            color: _sessionDuration == duration
                                ? _accent
                                : const Color(0xFF49405D),
                          ),
                          labelStyle: TextStyle(
                            color: _sessionDuration == duration
                                ? OledTheme.bg
                                : OledTheme.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          backgroundColor: const Color(0xFF2A233B),
                          selectedColor: _accent,
                          onSelected: (selected) {
                            if (!selected) return;
                            HapticFeedback.selectionClick();
                            setState(() => _sessionDuration = duration);
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Practice days', style: _sectionLabel),
                  const SizedBox(height: 6),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final evenlySpacedWidth = (constraints.maxWidth - 24) / 7;
                      final width = math.max(
                        evenlySpacedWidth,
                        MediaQuery.textScalerOf(context).scale(33),
                      );
                      return Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          for (final day in _weekDays)
                            SizedBox(width: width, child: _buildDay(day)),
                        ],
                      );
                    },
                  ),
                  const Divider(height: 22, color: Color(0xFF49405D)),
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.calendarClock,
                        color: _accent,
                        size: 17,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedDays.isEmpty
                              ? 'Select at least one practice day'
                              : '${weeklyHours.toStringAsFixed(1)} hrs / week · ${_selectedDays.length} ${_selectedDays.length == 1 ? 'session' : 'sessions'}',
                          style: const TextStyle(
                            color: OledTheme.textPrimary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
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
            label: Text(isEditing ? 'Update Skill' : 'Create Skill'),
          ),
        ],
      ),
    );
  }

  Widget _buildDay(String day) {
    final selected = _selectedDays.contains(day);
    return Semantics(
      selected: selected,
      label: day,
      child: OutlinedButton(
        onPressed: () => _toggleDay(day),
        style: OutlinedButton.styleFrom(
          backgroundColor: selected
              ? const Color(0xFF443864)
              : Colors.transparent,
          foregroundColor: selected
              ? OledTheme.textPrimary
              : OledTheme.textSecondary,
          minimumSize: const Size(0, 40),
          padding: EdgeInsets.zero,
          side: BorderSide(color: selected ? _accent : const Color(0xFF49405D)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
        child: ExcludeSemantics(child: Text(day.substring(0, 3))),
      ),
    );
  }

  static const _sectionLabel = TextStyle(
    color: OledTheme.textSecondary,
    fontWeight: FontWeight.w600,
    fontSize: 12,
  );
}
