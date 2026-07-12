import 'package:cloud_firestore/cloud_firestore.dart';

class AcademicResource {
  final String id;
  final String title;
  final String subtitle;
  final String type;
  final String college;
  final double price;
  final String authorUid;
  final String authorName;
  final String fileUrl;
  final String fileName;
  final int fileSize;
  final String meta;
  final DateTime? createdAt;

  AcademicResource({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.college,
    required this.price,
    required this.authorUid,
    required this.authorName,
    required this.fileUrl,
    required this.fileName,
    required this.fileSize,
    required this.meta,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subtitle': subtitle,
      'type': type,
      'college': college,
      'price': price,
      'authorUid': authorUid,
      'authorName': authorName,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'fileSize': fileSize,
      'meta': meta,
      'createdAt': FieldValue.serverTimestamp(), // Always use server time for consistency
    };
  }
  factory AcademicResource.fromMap(Map<String, dynamic> map, String documentId) {
    return AcademicResource(
      id: documentId,
      title: map['title'] ?? '',
      subtitle: map['subtitle'] ?? '',
      type: map['type'] ?? '',
      college: map['college'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      authorUid: map['authorUid'] ?? '',
      authorName: map['authorName'] ?? '',
      fileUrl: map['fileUrl'] ?? '',
      fileName: map['fileName'] ?? '',
      fileSize: (map['fileSize'] ?? 0).toInt(),
      meta: map['meta'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}