enum DocumentType { pdf, word, image }

class DocumentItem {
  const DocumentItem({
    required this.id,
    required this.title,
    required this.date,
    required this.sizeLabel,
    required this.type,
    required this.pages,
    required this.folder,
    required this.path,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String date;
  final String sizeLabel;
  final DocumentType type;
  final int pages;
  final String folder;
  final String path;
  final DateTime createdAt;

  bool matches(String query) {
    final value = query.trim().toLowerCase();
    if (value.isEmpty) {
      return true;
    }

    return title.toLowerCase().contains(value) ||
        folder.toLowerCase().contains(value) ||
        type.name.toLowerCase().contains(value);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'date': date,
      'sizeLabel': sizeLabel,
      'type': type.name,
      'pages': pages,
      'folder': folder,
      'path': path,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory DocumentItem.fromJson(Map<String, dynamic> json) {
    return DocumentItem(
      id: json['id'] as String,
      title: json['title'] as String,
      date: json['date'] as String,
      sizeLabel: json['sizeLabel'] as String,
      type: DocumentType.values.byName(json['type'] as String),
      pages: json['pages'] as int,
      folder: json['folder'] as String,
      path: json['path'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
