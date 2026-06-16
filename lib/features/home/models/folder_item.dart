import 'package:flutter/material.dart';

class FolderItem {
  const FolderItem({
    required this.name,
    required this.date,
    required this.fileCount,
    required this.accent,
  });

  final String name;
  final String date;
  final int fileCount;
  final Color accent;

  FolderItem copyWith({
    String? name,
    String? date,
    int? fileCount,
    Color? accent,
  }) {
    return FolderItem(
      name: name ?? this.name,
      date: date ?? this.date,
      fileCount: fileCount ?? this.fileCount,
      accent: accent ?? this.accent,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'date': date,
      'fileCount': fileCount,
      'accent': accent.toARGB32(),
    };
  }

  factory FolderItem.fromJson(Map<String, dynamic> json) {
    return FolderItem(
      name: json['name'] as String,
      date: json['date'] as String,
      fileCount: json['fileCount'] as int,
      accent: Color(json['accent'] as int),
    );
  }
}
