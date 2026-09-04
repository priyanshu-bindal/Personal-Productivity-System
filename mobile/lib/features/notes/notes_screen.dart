import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/animated_card.dart';
import '../../core/widgets/custom_bottom_sheet.dart';
import '../../core/widgets/traffic_loader.dart';
import '../../models/note.dart';
import '../../providers/notes_provider.dart';
import 'add_note_sheet.dart';

class NotesScreen extends ConsumerWidget {
  const NotesScreen({super.key});

  void _openAddNoteModal(BuildContext context, WidgetRef ref, [Note? existingNote]) async {
    final result = await CustomBottomSheet.show<Map<String, dynamic>>(
      context: context,
      title: existingNote != null ? 'Edit Note' : 'Create New Note',
      subtitle: 'Store thoughts, key learnings & references',
      child: AddNoteSheet(existingNote: existingNote),
    );

    if (result != null) {
      if (existingNote != null) {
        ref.read(notesProvider.notifier).updateNote(
              existingNote.id,
              title: result['title'] as String,
              content: result['content'] as String?,
              tags: result['tags'] as List<String>?,
              skillId: result['skillId'] as String?,
            );
      } else {
        ref.read(notesProvider.notifier).createNote(
              title: result['title'] as String,
              content: result['content'] as String?,
              tags: result['tags'] as List<String>?,
              skillId: result['skillId'] as String?,
            );
      }
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dateTime);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(notesProvider);
    final searchQuery = ref.watch(noteSearchQueryProvider);
    final isNewest = ref.watch(noteSortNewestProvider);

    List<Note> notes = notesAsync.value ?? [];

    if (searchQuery.trim().isNotEmpty) {
      final q = searchQuery.toLowerCase().trim();
      notes = notes.where((n) {
        final t = n.title.toLowerCase();
        final c = (n.content ?? '').toLowerCase();
        final tagsMatch = n.tags.any((tag) => tag.toLowerCase().contains(q));
        return t.contains(q) || c.contains(q) || tagsMatch;
      }).toList();
    }

    notes.sort((a, b) => isNewest ? b.createdAt.compareTo(a.createdAt) : a.createdAt.compareTo(b.createdAt));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Personal Notes',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isNewest ? LucideIcons.arrowDown : LucideIcons.arrowUp,
              color: AppColors.textSecondary,
            ),
            tooltip: isNewest ? 'Sort: Newest first' : 'Sort: Oldest first',
            onPressed: () {
              ref.read(noteSortNewestProvider.notifier).state = !isNewest;
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddNoteModal(context, ref),
        backgroundColor: AppColors.primary,
        child: const Icon(LucideIcons.plus, color: Colors.white),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(notesProvider.notifier).fetchNotes();
          },
          color: AppColors.primary,
          backgroundColor: AppColors.card,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: TextField(
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search notes by title, content, or tags...',
                    prefixIcon: const Icon(LucideIcons.search, color: AppColors.textMuted, size: 20),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(LucideIcons.x, color: AppColors.textMuted, size: 18),
                            onPressed: () => ref.read(noteSearchQueryProvider.notifier).state = '',
                          )
                        : null,
                  ),
                  onChanged: (val) => ref.read(noteSearchQueryProvider.notifier).state = val,
                ),
              ),

              Expanded(
                child: notesAsync.isLoading && notes.isEmpty
                    ? const Center(child: TrafficLoader(message: 'Loading notes...'))
                    : notes.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(LucideIcons.fileText, size: 48, color: AppColors.textMuted),
                                  const SizedBox(height: 16),
                                  Text(
                                    searchQuery.isNotEmpty ? 'No notes matching "$searchQuery"' : 'No notes created yet',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Keep your personal knowledge base simple and accessible.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                            itemCount: notes.length,
                            itemBuilder: (context, index) {
                              final note = notes[index];
                              return AnimatedCard(
                                index: index,
                                onTap: () => _openAddNoteModal(context, ref, note),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            note.title,
                                            style: const TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(LucideIcons.trash2, color: AppColors.textMuted, size: 18),
                                          onPressed: () {
                                            ref.read(notesProvider.notifier).deleteNote(note.id);
                                          },
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      ],
                                    ),
                                    if (note.content != null && note.content!.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        note.content!,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: AppColors.textSecondary,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        if (note.tags.isNotEmpty)
                                          Wrap(
                                            spacing: 6,
                                            children: note.tags.take(3).map((tag) {
                                              return Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppColors.surface,
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(color: AppColors.border),
                                                ),
                                                child: Text(
                                                  '#$tag',
                                                  style: const TextStyle(fontSize: 11, color: AppColors.accentCyan),
                                                ),
                                              );
                                            }).toList(),
                                          )
                                        else
                                          const SizedBox.shrink(),
                                        Text(
                                          'Updated ${_formatTimeAgo(note.updatedAt)}',
                                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
