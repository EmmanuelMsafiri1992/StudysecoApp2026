class LibraryMaterialModel {
  final int id;
  final String title;
  final String? description;
  final String? fileType;
  final int? fileSize;
  final int? subjectId;
  final String? subjectName;
  final String? teacherName;
  final String? fileUrl;
  final int viewCount;
  final DateTime createdAt;

  LibraryMaterialModel({
    required this.id,
    required this.title,
    this.description,
    this.fileType,
    this.fileSize,
    this.subjectId,
    this.subjectName,
    this.teacherName,
    this.fileUrl,
    this.viewCount = 0,
    required this.createdAt,
  });

  factory LibraryMaterialModel.fromJson(Map<String, dynamic> json) {
    final rawUrl = json['file_url'] ?? json['url'] ?? json['download_url'] ?? json['path'];
    String? fileUrl;
    if (rawUrl != null && rawUrl.toString().isNotEmpty) {
      final s = rawUrl.toString();
      fileUrl = s.startsWith('http') ? s : 'https://studyseco.com$s';
    }
    final rawCreatedAt = json['created_at'] ?? json['uploaded_at'] ?? json['date'];
    DateTime createdAt;
    try {
      createdAt = rawCreatedAt != null ? DateTime.parse(rawCreatedAt.toString()) : DateTime.now();
    } catch (_) {
      createdAt = DateTime.now();
    }
    final rawId = json['id'];
    final id = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '') ?? 0;
    final subject = json['subject'] as Map?;
    final teacher = json['teacher'] as Map? ?? json['uploaded_by'] as Map?;
    return LibraryMaterialModel(
      id: id,
      title: json['title'] ?? json['name'] ?? '',
      description: json['description'],
      fileType: json['file_type'] ?? json['type'] ?? json['format'],
      fileSize: json['file_size'] ?? json['size'],
      subjectId: json['subject_id'] ?? subject?['id'],
      subjectName: json['subject_name'] ?? subject?['name'],
      teacherName: json['teacher_name'] ?? json['uploader_name'] ?? teacher?['name'],
      fileUrl: fileUrl,
      viewCount: json['view_count'] ?? json['views'] ?? 0,
      createdAt: createdAt,
    );
  }

  String get fileSizeLabel {
    if (fileSize == null) return '';
    if (fileSize! < 1024) return '${fileSize}B';
    if (fileSize! < 1024 * 1024) return '${(fileSize! / 1024).toStringAsFixed(1)}KB';
    return '${(fileSize! / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  String get typeLabel {
    final t = (fileType ?? '').toLowerCase();
    if (t == 'pdf') return 'PDF';
    if (t == 'doc' || t == 'docx') return 'Word';
    if (t == 'ppt' || t == 'pptx') return 'PowerPoint';
    if (t == 'xls' || t == 'xlsx') return 'Excel';
    if (['jpg', 'jpeg', 'png'].contains(t)) return 'Image';
    return t.isNotEmpty ? t.toUpperCase() : 'File';
  }
}
