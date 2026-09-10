import 'package:flutter/material.dart';

enum IdMarkerSize { sm, md, lg }

/// Monogram avatar marker matching the website chat IdMarker.
class IdMarker extends StatelessWidget {
  final String id;
  final String? name;
  final IdMarkerSize size;

  const IdMarker({
    super.key,
    required this.id,
    this.name,
    this.size = IdMarkerSize.md,
  });

  String get _initials {
    final cleanName = name?.trim() ?? '';
    if (cleanName.isNotEmpty) {
      final parts = cleanName.split(' ').where((s) => s.isNotEmpty).toList();
      if (parts.length >= 2) {
        return (parts[0][0] + parts[1][0]).toUpperCase();
      } else if (parts.isNotEmpty) {
        return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
      }
    }
    final cleanId = id.replaceAll('#', '').trim();
    if (cleanId.length >= 2) {
      return cleanId.substring(0, 2).toUpperCase();
    }
    return cleanId.isNotEmpty ? cleanId.toUpperCase() : 'FF';
  }

  double get _dimension {
    switch (size) {
      case IdMarkerSize.sm:
        return 34.0;
      case IdMarkerSize.lg:
        return 46.0;
      case IdMarkerSize.md:
        return 40.0;
    }
  }

  double get _fontSize {
    switch (size) {
      case IdMarkerSize.sm:
        return 11.5;
      case IdMarkerSize.lg:
        return 15.0;
      case IdMarkerSize.md:
        return 13.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dim = _dimension;

    return Container(
      width: dim,
      height: dim,
      decoration: BoxDecoration(
        color: const Color(0x1F3B5B8C), // rgba(59, 91, 140, 0.12)
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0x593B5B8C), // rgba(59, 91, 140, 0.35)
          width: 1.0,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: TextStyle(
          color: const Color(0xFF7E9ED4),
          fontWeight: FontWeight.bold,
          fontSize: _fontSize,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
