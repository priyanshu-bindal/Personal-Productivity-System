import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
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
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  final _nameFocusNode = FocusNode();

  late String _selectedCategory;
  late String _selectedLevel;
  late int _sessionDuration;
  late Set<String> _selectedDays;

  late final List<PremiumDropdownItem<String>> _categoryItems;
  late final List<PremiumDropdownItem<String>> _levelItems;

  bool _isSubmitting = false;
  bool _isNameFocused = false;

  final Map<String, AnimationController> _dayControllers = {};
  final Map<String, Animation<double>> _dayScales = {};

  static const List<String> _weekDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const List<String> _dayShortLabels = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  static const List<int> _durations = [30, 45, 60, 90, 120];

  // Design Tokens (Refined Dark Palette - No Bright Glow)
  static const Color _surfaceCard = Color(0xFF16161B);
  static const Color _surfaceInput = Color(0xFF1A1A20);
  static const Color _surfaceSelected = Color(0xFF1D263B);
  static const Color _borderColor = Color(0xFF26262C);
  static const Color _borderActive = Color(0xFF3B82F6);
  static const Color _textPrimary = Color(0xFFF4F4F5);
  static const Color _textSecondary = Color(0xFFA1A1AA);
  static const Color _textMuted = Color(0xFF71717A);
  static const Color _accent = Color(0xFF3B82F6);

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
        .map((c) => PremiumDropdownItem<String>(
              value: c,
              label: c,
              icon: _getCategoryIcon(c),
              iconColor: _textSecondary,
            ))
        .toList();

    _levelItems = AppConstants.skillLevels
        .map((l) => PremiumDropdownItem<String>(
              value: l,
              label: l,
              icon: _getLevelIcon(l),
              iconColor: _textSecondary,
            ))
        .toList();

    _nameFocusNode.addListener(() {
      if (mounted) {
        setState(() {
          _isNameFocused = _nameFocusNode.hasFocus;
        });
      }
    });

    for (final day in _weekDays) {
      final ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 160),
      );
      _dayControllers[day] = ctrl;
      _dayScales[day] = Tween<double>(begin: 0.92, end: 1.0).animate(
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
    HapticFeedback.selectionClick();
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

  String _formatDuration(int mins) {
    if (mins >= 60) {
      final hrs = mins / 60;
      return hrs == hrs.roundToDouble() ? '${hrs.toInt()}h' : '${hrs.toStringAsFixed(1)}h';
    }
    return '${mins}m';
  }

  @override
  Widget build(BuildContext context) {
    final weeklyMinutes = _selectedDays.length * _sessionDuration;
    final weeklyHours = weeklyMinutes / 60;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── 1. Skill Name Card ───────────────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _surfaceCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _isNameFocused ? _borderActive : _borderColor,
                width: _isNameFocused ? 1.2 : 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'SKILL NAME',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.9,
                        color: _textMuted,
                      ),
                    ),
                    if (_nameController.text.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _nameController.clear();
                          setState(() {});
                        },
                        behavior: HitTestBehavior.opaque,
                        child: const Padding(
                          padding: EdgeInsets.all(2.0),
                          child: Icon(
                            LucideIcons.x,
                            size: 14,
                            color: _textMuted,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      _getCategoryIcon(_selectedCategory),
                      size: 18,
                      color: _isNameFocused ? _accent : _textSecondary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _nameController,
                        focusNode: _nameFocusNode,
                        onChanged: (_) => setState(() {}),
                        textCapitalization: TextCapitalization.words,
                        style: const TextStyle(
                          color: _textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        cursorColor: _accent,
                        decoration: const InputDecoration(
                          hintText: 'e.g. System Design, Guitar, Spanish',
                          hintStyle: TextStyle(
                            color: _textMuted,
                            fontSize: 14,
                            fontWeight: FontWeight.normal,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Please enter skill name'
                            : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── 2. Category & Level Dropdowns ────────────────────────────
          Row(
            children: [
              Expanded(
                child: PremiumDropdownField<String>(
                  label: 'Category',
                  value: _selectedCategory,
                  items: _categoryItems,
                  onChanged: (val) {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedCategory = val);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PremiumDropdownField<String>(
                  label: 'Level',
                  value: _selectedLevel,
                  items: _levelItems,
                  onChanged: (val) {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedLevel = val);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // ── 3. Target Session Duration ───────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'SESSION DURATION',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.9,
                  color: _textMuted,
                ),
              ),
              Text(
                '$_sessionDuration min / session',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: _textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: _durations.map((duration) {
              final isSelected = _sessionDuration == duration;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3.0),
                  child: PressableScale(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _sessionDuration = duration);
                    },
                    scaleFactor: 0.94,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      curve: Curves.easeOutCubic,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected ? _surfaceSelected : _surfaceCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? _borderActive : _borderColor,
                          width: isSelected ? 1.2 : 1.0,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _formatDuration(duration),
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected ? _textPrimary : _textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),

          // ── 4. Preferred Practice Days ───────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'PRACTICE DAYS',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.9,
                  color: _textMuted,
                ),
              ),
              Text(
                '${_selectedDays.length} days / week',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: _selectedDays.isNotEmpty ? _accent : _textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(_weekDays.length, (index) {
              final day = _weekDays[index];
              final label = _dayShortLabels[index];
              final isSelected = _selectedDays.contains(day);

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.5),
                  child: ScaleTransition(
                    scale: _dayScales[day]!,
                    child: GestureDetector(
                      onTap: () => _toggleDay(day),
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        curve: Curves.easeOutCubic,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isSelected ? _surfaceSelected : _surfaceCard,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? _borderActive : _borderColor,
                            width: isSelected ? 1.2 : 1.0,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              label,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color:
                                    isSelected ? _textPrimary : _textMuted,
                              ),
                            ),
                            const SizedBox(height: 3),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              width: isSelected ? 4 : 0,
                              height: 4,
                              decoration: BoxDecoration(
                                color: isSelected ? _accent : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),

          // ── 5. Commitment Insight Banner ─────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _surfaceInput,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _borderColor, width: 0.8),
            ),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.calendarClock,
                  size: 15,
                  color: _accent,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    _selectedDays.isEmpty
                        ? 'Select at least 1 day to set schedule'
                        : '~${weeklyHours.toStringAsFixed(1)} hrs / week target • ${_selectedDays.length} sessions',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _textSecondary,
                    ),
                  ),
                ),
              ],
            ),
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
                            widget.existingSkillId != null
                                ? LucideIcons.check
                                : LucideIcons.plus,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.existingSkillId != null
                                ? 'Update Skill'
                                : 'Create Skill',
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
