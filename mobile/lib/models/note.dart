class Note {
  final String id;
  final String userId;
  final String? skillId;
  final String? skillName;
  final String title;
  final String? content;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  Note({
    required this.id,
    required this.userId,
    this.skillId,
    this.skillName,
    required this.title,
    this.content,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    String? sName;
    if (json['skill'] != null && json['skill'] is Map) {
      sName = json['skill']['name'] as String?;
    }

    final rawTags = json['tags'];
    List<String> parsedTags = [];
    if (rawTags is List) {
      parsedTags = rawTags.map((e) => e.toString()).toList();
    } else if (rawTags is String && rawTags.isNotEmpty) {
      parsedTags = rawTags.split(',').map((e) => e.trim()).toList();
    }

    return Note(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      skillId: json['skill_id'] as String?,
      skillName: sName,
      title: json['title'] as String,
      content: json['content'] as String?,
      tags: parsedTags,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'title': title,
      'content': content,
      'tags': tags,
      'skill_id': skillId,
    };
  }
}
