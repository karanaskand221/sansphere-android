import 'package:flutter_test/flutter_test.dart';
import 'package:sansphere_android/models/academic_resource.dart';

void main() {
  group('AcademicResource', () {
    test('fromMap parses all fields correctly', () {
      final map = {
        'customDocId': 'DS-NOTES-01',
        'title': 'Data Structures Notes',
        'subtitle': 'Unit 1-5 complete notes',
        'type': 'Notes',
        'college': 'SITRC',
        'price': 49.0,
        'authorUid': 'uid123',
        'authorName': 'Asha Patil',
        'fileUrl': 'https://example.com/file.pdf',
        'fileName': 'notes.pdf',
        'fileSize': 204800,
        'meta': '1 File • 0.2 MB',
      };

      final resource = AcademicResource.fromMap(map, 'doc123');

      expect(resource.id, 'doc123');
      expect(resource.customDocId, 'DS-NOTES-01');
      expect(resource.title, 'Data Structures Notes');
      expect(resource.price, 49.0);
      expect(resource.fileUrl, 'https://example.com/file.pdf');
    });

    test('fromMap falls back to defaults for missing fields', () {
      final resource = AcademicResource.fromMap(const {}, 'doc456');

      expect(resource.title, '');
      expect(resource.customDocId, '');
      expect(resource.price, 0.0);
      expect(resource.fileSize, 0);
    });

    test('toMap includes all editable fields', () {
      final resource = AcademicResource(
        id: 'doc789',
        customDocId: 'CODE-101',
        title: 'Title',
        subtitle: 'Subtitle',
        type: 'Code',
        college: 'SIEM',
        price: 0.0,
        authorUid: 'uid456',
        authorName: 'Author',
        fileUrl: 'https://example.com/file.zip',
        fileName: 'file.zip',
        fileSize: 1024,
        meta: '1 File',
      );

      final map = resource.toMap();

      expect(map['title'], 'Title');
      expect(map['customDocId'], 'CODE-101');
      expect(map['fileUrl'], 'https://example.com/file.zip');
      expect(map.containsKey('createdAt'), isTrue);
    });
  });
}
