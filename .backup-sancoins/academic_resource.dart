import 'package:cloud_firestore/cloud_firestore.dart';

enum ResourceCategory {
  lectureNotes,
  pyq,
  questionBank,
  testPaper,
  textbook,
  questionPaper,
  labManual,
  assignment,
  other,
}

extension ResourceCategoryExtension on ResourceCategory {
  String get displayName {
    switch (this) {
      case ResourceCategory.lectureNotes:
        return 'Lecture Notes';
      case ResourceCategory.pyq:
        return 'Previous Year Questions (PYQ)';
      case ResourceCategory.questionBank:
        return 'Question Bank';
      case ResourceCategory.testPaper:
        return 'Test Paper';
      case ResourceCategory.textbook:
        return 'Textbook';
      case ResourceCategory.questionPaper:
        return 'Question Paper';
      case ResourceCategory.labManual:
        return 'Lab Manual';
      case ResourceCategory.assignment:
        return 'Assignment';
      case ResourceCategory.other:
        return 'Other';
    }
  }
}

class AcademicResource {
  final String id;
  final String customDocId;
  final String title;
  final String description;
  final String subject;
  final String college;
  final String department;
  final String type;
  final double price;
  final String fileUrl;
  final String uploaderId;
  final String uploaderName;
  final DateTime createdAt;

  // Academic-vault compatibility fields.
  final int semester;
  final ResourceCategory category;
  final String fileName;
  final double fileSizeMb;
  final DateTime uploadDate;
  final int downloadCount;
  final double rating;
  final List<String> tags;

  final String subtitle;
  final String authorUid;
  final String authorName;
  final double fileSize;
  final String meta;
  AcademicResource({
    this.subtitle = '',
    this.authorUid = '',
    this.authorName = 'Anonymous',
    this.fileSize = 0.0,
    this.meta = '',
    this.id = '',
    this.customDocId = '',
    this.title = '',
    this.description = '',
    this.subject = '',
    this.college = '',
    this.department = '',
    this.type = 'Lecture Notes',
    this.price = 0.0,
    this.fileUrl = '',
    this.uploaderId = '',
    this.uploaderName = 'Anonymous',
    DateTime? createdAt,
    this.semester = 1,
    this.category = ResourceCategory.lectureNotes,
    this.fileName = '',
    this.fileSizeMb = 0.0,
    DateTime? uploadDate,
    this.downloadCount = 0,
    this.rating = 0.0,
    this.tags = const [],
  }) : createdAt = createdAt ?? uploadDate ?? DateTime.now(),
       uploadDate = uploadDate ?? createdAt ?? DateTime.now();

  factory AcademicResource.fromMap(Map<String, dynamic> map, [String? docId]) {
    final dynamic timestamp = map['createdAt'] ?? map['uploadDate'];

    DateTime parsedDate = DateTime.now();

    if (timestamp is Timestamp) {
      parsedDate = timestamp.toDate();
    } else if (timestamp is DateTime) {
      parsedDate = timestamp;
    } else if (timestamp is String) {
      parsedDate = DateTime.tryParse(timestamp) ?? DateTime.now();
    }

    ResourceCategory parsedCategory = ResourceCategory.lectureNotes;

    final categoryValue = map['category'];

    if (categoryValue is String) {
      parsedCategory = ResourceCategory.values.firstWhere(
        (category) =>
            category.name == categoryValue ||
            category.displayName == categoryValue,
        orElse: () => ResourceCategory.lectureNotes,
      );
    }

    final dynamic tagsValue = map['tags'];

    final List<String> parsedTags = tagsValue is List
        ? tagsValue.map((e) => e.toString()).toList()
        : <String>[];

    return AcademicResource(
      id: docId ?? map['id']?.toString() ?? '',
      customDocId: map['customDocId']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      subtitle: map['subtitle']?.toString() ?? '',
      authorUid:
          map['authorUid']?.toString() ?? map['uploaderId']?.toString() ?? '',
      authorName:
          map['authorName']?.toString() ??
          map['uploaderName']?.toString() ??
          'Anonymous',
      meta: map['meta']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      subject: map['subject']?.toString() ?? '',
      college: map['college']?.toString() ?? '',
      department: map['department']?.toString() ?? '',
      type:
          map['type']?.toString() ??
          map['category']?.toString() ??
          'Lecture Notes',
      price: _toDouble(map['price']),
      fileUrl: map['fileUrl']?.toString() ?? '',
      uploaderId:
          map['uploaderId']?.toString() ?? map['authorUid']?.toString() ?? '',
      uploaderName:
          map['uploaderName']?.toString() ??
          map['authorName']?.toString() ??
          'Anonymous',
      createdAt: parsedDate,
      semester: _toInt(map['semester'], 1),
      category: parsedCategory,
      fileName: map['fileName']?.toString() ?? '',
      fileSizeMb: _toDouble(map['fileSizeMb'] ?? map['fileSize']),
      uploadDate: parsedDate,
      downloadCount: _toInt(map['downloadCount'], 0),
      rating: _toDouble(map['rating']),
      tags: parsedTags,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customDocId': customDocId,
      'title': title,
      'description': description,
      'subject': subject,
      'college': college,
      'department': department,
      'type': type,
      'price': price,
      'fileUrl': fileUrl,
      'uploaderId': uploaderId,
      'uploaderName': uploaderName,
      'createdAt': Timestamp.fromDate(createdAt),

      // Academic-vault fields.
      'semester': semester,
      'category': category.name,
      'fileName': fileName,
      'fileSizeMb': fileSizeMb,
      'fileSize': fileSize,
      'uploadDate': Timestamp.fromDate(uploadDate),
      'downloadCount': downloadCount,
      'rating': rating,
      'tags': tags,
    };
  }

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  static int _toInt(dynamic value, [int fallback = 0]) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
