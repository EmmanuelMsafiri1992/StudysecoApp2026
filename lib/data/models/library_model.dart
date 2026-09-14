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
    return LibraryMaterialModel(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'],
      fileType: json['file_type'],
      fileSize: json['file_size'],
      subjectId: json['subject_id'],
      subjectName: json['subject_name'],
      teacherName: json['teacher_name'],
      fileUrl: json['file_url'],
      viewCount: json['view_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
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
