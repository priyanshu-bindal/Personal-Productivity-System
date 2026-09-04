import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/pressable_scale.dart';
import '../../models/note.dart';
import '../../providers/skills_provider.dart';

class AddNoteSheet extends ConsumerStatefulWidget {
  final Note? existingNote;

  const AddNoteSheet({super.key, this.existingNote});

  @override
  ConsumerState<AddNoteSheet> createState() => _AddNoteSheetState();
}

class _AddNoteSheetState extends ConsumerState<AddNoteSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _tagsController;
  String? _selectedSkillId;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existingNote?.title ?? '');
    _contentController = TextEditingController(text: widget.existingNote?.content ?? '');
    _tagsController = TextEditingController(
      text: widget.existingNote?.tags.join(', ') ?? '',
    );
    _selectedSkillId = widget.existingNote?.skillId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final tags = _tagsController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final result = {
      'title': _titleController.text.trim(),
      'content': _contentController.text.trim(),
      'tags': tags,
      'skillId': _selectedSkillId,
    };

    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final skills = ref.watch(skillsProvider).value ?? [];

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          TextFormField(
            controller: _titleController,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Note Title',
              hintText: 'e.g. Binary Search Edge Cases',
              prefixIcon: Icon(LucideIcons.fileText, color: AppColors.textMuted, size: 20),
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter note title' : null,
          ),
          const SizedBox(height: 16),

          // Content
          TextFormField(
            controller: _contentController,
            maxLines: 4,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Note Content',
              hintText: 'Write your notes, key takeaways, code snippets or formulas...',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),

          // Optional Skill Association
          DropdownButtonFormField<String?>(
            initialValue: _selectedSkillId,
            dropdownColor: AppColors.card,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Associated Skill (Optional)',
              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('General / None', style: TextStyle(color: AppColors.textMuted)),
              ),
              ...skills.map((s) => DropdownMenuItem<String?>(
                    value: s.id,
                    child: Text(s.name),
                  )),
            ],
            onChanged: (val) => setState(() => _selectedSkillId = val),
          ),
          const SizedBox(height: 16),

          // Tags
          TextFormField(
            controller: _tagsController,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Tags (comma separated)',
              hintText: 'e.g. dsa, trees, revision',
              prefixIcon: Icon(LucideIcons.tag, color: AppColors.textMuted, size: 20),
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
              child: Center(
                child: Text(
                  widget.existingNote != null ? 'Save Note' : 'Create Note',
                  style: const TextStyle(
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
