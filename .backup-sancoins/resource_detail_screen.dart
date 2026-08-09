import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../global_state.dart';
import '../models/academic_resource.dart';

class ResourceDetailScreen extends StatefulWidget {
  final AcademicResource resource;
  final GlobalState globalState;

  const ResourceDetailScreen({
    super.key,
    required this.resource,
    required this.globalState,
  });

  @override
  State<ResourceDetailScreen> createState() => _ResourceDetailScreenState();
}

class _ResourceDetailScreenState extends State<ResourceDetailScreen> {
  bool _opening = false;

  late final FirebaseFirestore _vaultFirestore;

  @override
  void initState() {
    super.initState();

    _vaultFirestore = FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'sanvault',
    );
  }

  Future<void> _openFile() async {
    final url = widget.resource.fileUrl.trim();

    if (url.isEmpty) {
      _showError('This resource does not have a file URL.');
      return;
    }

    setState(() {
      _opening = true;
    });

    try {
      final uri = Uri.tryParse(url);

      if (uri == null) {
        throw Exception('Invalid file URL');
      }

      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        throw Exception('Could not open file');
      }

      await _incrementDownloadCount();
    } catch (e) {
      _showError('Could not open file: $e');
    } finally {
      if (mounted) {
        setState(() {
          _opening = false;
        });
      }
    }
  }

  Future<void> _incrementDownloadCount() async {
    final docId = widget.resource.id.isNotEmpty
        ? widget.resource.id
        : widget.resource.customDocId;

    if (docId.isEmpty) return;

    try {
      await _vaultFirestore.collection('academic_vault').doc(docId).update({
        'downloadCount': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('Download count update failed: $e');
    }
  }

  String _formatSize(double mb) {
    if (mb <= 0) return 'Unknown size';

    if (mb < 1) {
      return '${(mb * 1024).toStringAsFixed(0)} KB';
    }

    return '${mb.toStringAsFixed(2)} MB';
  }

  IconData _fileIcon(String name) {
    final extension = name.split('.').last.toLowerCase();

    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'doc':
      case 'docx':
        return Icons.article_rounded;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow_rounded;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart_rounded;
      case 'zip':
        return Icons.folder_zip_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final resource = widget.resource;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Resource Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 78,
                    height: 78,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      _fileIcon(resource.fileName),
                      size: 42,
                      color: const Color(0xFF2563EB),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    resource.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    resource.fileName.isEmpty
                        ? 'Academic Resource'
                        : resource.fileName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),

                  const SizedBox(height: 18),

                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _infoChip(
                        Icons.storage_rounded,
                        _formatSize(resource.fileSizeMb),
                      ),
                      _infoChip(
                        Icons.download_rounded,
                        '${resource.downloadCount} downloads',
                      ),
                      _infoChip(Icons.school_rounded, resource.department),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            _section(
              title: 'About this resource',
              child: Text(
                resource.description.isEmpty
                    ? 'No description provided.'
                    : resource.description,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.55,
                  color: Color(0xFF334155),
                ),
              ),
            ),

            const SizedBox(height: 16),

            _section(
              title: 'Resource Information',
              child: Column(
                children: [
                  _detailRow('Subject', resource.subject),
                  _detailRow('Category', resource.type),
                  _detailRow('Semester', 'Semester ${resource.semester}'),
                  _detailRow('Department', resource.department),
                  _detailRow('College', resource.college),
                  _detailRow('Uploaded by', resource.uploaderName),
                  _detailRow('Document ID', resource.customDocId),
                ],
              ),
            ),

            const SizedBox(height: 16),

            if (resource.tags.isNotEmpty)
              _section(
                title: 'Tags',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: resource.tags.map((tag) {
                    return Chip(
                      label: Text(tag),
                      backgroundColor: const Color(0xFFEFF6FF),
                    );
                  }).toList(),
                ),
              ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _opening ? null : _openFile,
                icon: _opening
                    ? const SizedBox(
                        height: 21,
                        width: 21,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.open_in_new_rounded),
                label: Text(
                  _opening ? 'Opening...' : 'Open / Download File',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _section({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'Not specified' : value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: const Color(0xFF475569)),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
