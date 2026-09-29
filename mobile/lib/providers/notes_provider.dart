import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/note.dart';
import '../services/supabase_service.dart';
import 'auth_provider.dart';

final noteSearchQueryProvider = StateProvider<String>((ref) => '');
final noteSortNewestProvider = StateProvider<bool>((ref) => true);

final notesProvider = StateNotifierProvider<NotesNotifier, AsyncValue<List<Note>>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  return NotesNotifier(userId);
});

class NotesNotifier extends StateNotifier<AsyncValue<List<Note>>> {
  final String? _userId;

  NotesNotifier([this._userId])
      : super(_userId == null ? const AsyncValue.data([]) : const AsyncValue.loading()) {
    if (_userId != null) {
      fetchNotes();
    }
  }

  Future<void> fetchNotes() async {
    final effectiveUserId = _userId ?? SupabaseService.currentUserId;
    if (effectiveUserId == null ||
        !mounted ||
        SupabaseService.currentUserId != effectiveUserId) {
      if (mounted) state = const AsyncValue.data([]);
      return;
    }

    try {
      final res = await SupabaseService.client
          .from('notes')
          .select('*, skill:skills(name)')
          .eq('user_id', effectiveUserId)
          .order('created_at', ascending: false);

      if (!mounted || SupabaseService.currentUserId != effectiveUserId) return;
      final list = (res as List).map((e) => Note.fromJson(e as Map<String, dynamic>)).toList();
      state = AsyncValue.data(list);
    } catch (e, st) {
      if (!mounted || SupabaseService.currentUserId != effectiveUserId) return;
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> createNote({
    required String title,
    String? content,
    List<String>? tags,
    String? skillId,
  }) async {
    final effectiveUserId = _userId ?? SupabaseService.currentUserId;
    if (effectiveUserId == null ||
        !mounted ||
        SupabaseService.currentUserId != effectiveUserId) {
      return;
    }

    try {
      await SupabaseService.client.from('notes').insert({
        'user_id': effectiveUserId,
        'title': title,
        'content': content,
        'tags': tags ?? [],
        'skill_id': skillId,
      });
      await fetchNotes();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateNote(String noteId, {
    required String title,
    String? content,
    List<String>? tags,
    String? skillId,
  }) async {
    final effectiveUserId = _userId ?? SupabaseService.currentUserId;
    if (effectiveUserId == null ||
        !mounted ||
        SupabaseService.currentUserId != effectiveUserId) {
      return;
    }

    try {
      await SupabaseService.client.from('notes').update({
        'title': title,
        'content': content,
        'tags': tags ?? [],
        'skill_id': skillId,
      }).eq('id', noteId).eq('user_id', effectiveUserId);
      await fetchNotes();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteNote(String noteId) async {
    final effectiveUserId = _userId ?? SupabaseService.currentUserId;
    if (effectiveUserId == null ||
        !mounted ||
        SupabaseService.currentUserId != effectiveUserId) {
      return;
    }

    try {
      await SupabaseService.client
          .from('notes')
          .delete()
          .eq('id', noteId)
          .eq('user_id', effectiveUserId);
      await fetchNotes();
    } catch (e) {
      rethrow;
    }
  }
}
