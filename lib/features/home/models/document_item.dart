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
    this.ocrText,
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
  final String? ocrText;

  bool get hasOcrText => ocrText != null && ocrText!.trim().isNotEmpty;

  bool matches(String query) {
    final value = query.trim().toLowerCase();
    if (value.isEmpty) {
      return true;
    }

    return title.toLowerCase().contains(value) ||
        folder.toLowerCase().contains(value) ||
        type.name.toLowerCase().contains(value) ||
        (ocrText?.toLowerCase().contains(value) ?? false);
  }

  DocumentItem copyWith({
    String? id,
    String? title,
    String? date,
    String? sizeLabel,
    DocumentType? type,
    int? pages,
    String? folder,
    String? path,
    DateTime? createdAt,
    String? ocrText,
  }) {
    return DocumentItem(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      sizeLabel: sizeLabel ?? this.sizeLabel,
      type: type ?? this.type,
      pages: pages ?? this.pages,
      folder: folder ?? this.folder,
      path: path ?? this.path,
      createdAt: createdAt ?? this.createdAt,
      ocrText: ocrText ?? this.ocrText,
    );
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
      'ocrText': ocrText,
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
      ocrText: json['ocrText'] as String?,
    );
  }
}
