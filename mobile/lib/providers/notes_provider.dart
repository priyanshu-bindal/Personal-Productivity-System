import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/note.dart';
import '../services/supabase_service.dart';

final noteSearchQueryProvider = StateProvider<String>((ref) => '');
final noteSortNewestProvider = StateProvider<bool>((ref) => true);

final notesProvider = StateNotifierProvider<NotesNotifier, AsyncValue<List<Note>>>((ref) {
  return NotesNotifier();
});

class NotesNotifier extends StateNotifier<AsyncValue<List<Note>>> {
  NotesNotifier() : super(const AsyncValue.loading()) {
    fetchNotes();
  }

  Future<void> fetchNotes() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) {
      state = const AsyncValue.data([]);
      return;
    }

    try {
      final res = await SupabaseService.client
          .from('notes')
          .select('*, skill:skills(name)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final list = (res as List).map((e) => Note.fromJson(e as Map<String, dynamic>)).toList();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> createNote({
    required String title,
    String? content,
    List<String>? tags,
    String? skillId,
  }) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return;

    await SupabaseService.client.from('notes').insert({
      'user_id': userId,
      'title': title,
      'content': content,
      'tags': tags ?? [],
      'skill_id': skillId,
    });
    await fetchNotes();
  }

  Future<void> updateNote(String noteId, {
    required String title,
    String? content,
    List<String>? tags,
    String? skillId,
  }) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return;

    await SupabaseService.client.from('notes').update({
      'title': title,
      'content': content,
      'tags': tags ?? [],
      'skill_id': skillId,
    }).eq('id', noteId);
    await fetchNotes();
  }

  Future<void> deleteNote(String noteId) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return;

    await SupabaseService.client.from('notes').delete().eq('id', noteId);
    await fetchNotes();
  }
}
