import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../global_state.dart';
import '../models/academic_resource.dart';

class UploadResourceScreen extends StatefulWidget {
  final GlobalState globalState;

  const UploadResourceScreen({super.key, required this.globalState});

  @override
  State<UploadResourceScreen> createState() => _UploadResourceScreenState();
}

class _UploadResourceScreenState extends State<UploadResourceScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _subjectController = TextEditingController();
  final _uploaderController = TextEditingController();
  final _tagsController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  late final FirebaseFirestore _vaultFirestore;
  late final FirebaseFirestore _userFirestore;
  late final FirebaseStorage _storage;

  ResourceCategory _selectedCategory = ResourceCategory.lectureNotes;
  String _selectedDepartment = 'Computer Engineering';
  int _selectedSemester = 4;

  PlatformFile? _selectedFile;

  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String _uploadStatus = '';

  final List<String> _departments = [
    'Computer Engineering',
    'Information Technology',
    'Mechanical Engineering',
    'Electrical Engineering',
    'Civil Engineering',
  ];

  @override
  void initState() {
    super.initState();

    final app = Firebase.app();

    _vaultFirestore = FirebaseFirestore.instanceFor(
      app: app,
      databaseId: 'sanvault',
    );

    _userFirestore = FirebaseFirestore.instanceFor(
      app: app,
      databaseId: 'sansphere',
    );

    _storage = FirebaseStorage.instanceFor(
      app: Firebase.app(),
      bucket: 'gen-lang-client-0227443307.firebasestorage.app',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _subjectController.dispose();
    _uploaderController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    if (_isUploading) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'doc',
          'docx',
          'ppt',
          'pptx',
          'xls',
          'xlsx',
          'txt',
          'zip',
        ],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final file = result.files.single;

      if (file.bytes == null || file.bytes!.isEmpty) {
        _showError('Could not read the selected file.');
        return;
      }

      // 25 MB safety limit.
      const maxBytes = 25 * 1024 * 1024;

      if (file.size > maxBytes) {
        _showError('File is too large. Maximum allowed size is 25 MB.');
        return;
      }

      setState(() {
        _selectedFile = file;
      });
    } catch (e) {
      _showError('Unable to select file: $e');
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }

    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  String _extension(String name) {
    final index = name.lastIndexOf('.');
    if (index == -1) return 'file';
    return name.substring(index + 1).toLowerCase();
  }

  String _safeFileName(String name) {
    return name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
  }

  String _categoryDisplayName(ResourceCategory category) {
    return category.displayName;
  }

  Future<Map<String, dynamic>> _getCurrentUserProfile(User user) async {
    try {
      final doc = await _userFirestore.collection('users').doc(user.uid).get();

      if (doc.exists && doc.data() != null) {
        return doc.data()!;
      }
    } catch (_) {}

    return {};
  }

  Future<void> _submitForm() async {
    if (_isUploading) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final file = _selectedFile;

    if (file == null || file.bytes == null || file.bytes!.isEmpty) {
      _showError('Please select a file first.');
      return;
    }

    final user = _auth.currentUser;

    if (user == null) {
      _showError('Please sign in before uploading.');
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _uploadStatus = 'Preparing upload...';
    });

    String? storagePath;

    try {
      final profile = await _getCurrentUserProfile(user);

      final String uploaderName = _uploaderController.text.trim().isNotEmpty
          ? _uploaderController.text.trim()
          : (profile['fullName'] ?? user.displayName ?? 'Student').toString();

      final String college = (profile['college'] ?? 'SITRC').toString();

      final String customDocId = 'SAN-${DateTime.now().millisecondsSinceEpoch}';

      final String safeName = _safeFileName(file.name);

      storagePath = 'academic_vault/${user.uid}/$customDocId/$safeName';

      setState(() {
        _uploadStatus = 'Uploading ${file.name}...';
      });

      final storageRef = FirebaseStorage.instanceFor(
        app: Firebase.app(),
        bucket: 'gen-lang-client-0227443307.firebasestorage.app',
      ).ref().child(storagePath);

      final metadata = SettableMetadata(
        contentType: _contentType(file.name),
        customMetadata: {
          'ownerUid': user.uid,
          'resourceId': customDocId,
          'originalName': file.name,
        },
      );

      await user.getIdToken(true);

      final refreshedUser = FirebaseAuth.instance.currentUser;
      if (refreshedUser == null) {
        throw FirebaseException(
          plugin: 'firebase_auth',
          code: 'unauthenticated',
          message:
              'Firebase Authentication session expired. Please sign in again.',
        );
      }

      final UploadTask uploadTask = storageRef.putData(file.bytes!, metadata);

      uploadTask.snapshotEvents.listen(
        (TaskSnapshot snapshot) {
          if (!mounted) return;

          final total = snapshot.totalBytes;

          setState(() {
            _uploadProgress = total > 0
                ? snapshot.bytesTransferred / total
                : 0.0;

            switch (snapshot.state) {
              case TaskState.running:
                _uploadStatus = 'Uploading...';
                break;
              case TaskState.paused:
                _uploadStatus = 'Upload paused';
                break;
              case TaskState.success:
                _uploadStatus = 'Upload complete';
                break;
              case TaskState.canceled:
                _uploadStatus = 'Upload cancelled';
                break;
              case TaskState.error:
                _uploadStatus = 'Upload error';
                break;
            }
          });
        },
        onError: (Object error) {
          debugPrint('Storage upload stream error: $error');
        },
      );

      final snapshot = await uploadTask;

      if (snapshot.state != TaskState.success) {
        throw FirebaseException(
          plugin: 'firebase_storage',
          code: 'upload-failed',
          message: 'Firebase Storage upload did not complete.',
        );
      }

      setState(() {
        _uploadProgress = 1.0;
        _uploadStatus = 'Creating resource record...';
      });

      final downloadUrl = await storageRef.getDownloadURL();

      final tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

      final now = FieldValue.serverTimestamp();

      final resourceData = <String, dynamic>{
        'customDocId': customDocId,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'subject': _subjectController.text.trim(),
        'college': college,
        'department': _selectedDepartment,
        'type': _categoryDisplayName(_selectedCategory),
        'category': _selectedCategory.name,
        'semester': _selectedSemester,
        'price': 0.0,

        'fileUrl': downloadUrl,
        'fileName': file.name,
        'fileSizeMb': file.size / (1024 * 1024),
        'fileSize': file.size / (1024 * 1024),
        'fileExtension': _extension(file.name),
        'storagePath': storagePath,

        'uploaderId': user.uid,
        'uploaderName': uploaderName,
        'authorUid': user.uid,
        'authorName': uploaderName,

        'downloadCount': 0,
        'rating': 0.0,
        'tags': tags.isEmpty ? ['Academic', 'Study'] : tags,

        'createdAt': now,
        'uploadDate': now,

        'status': 'published',
      };

      await _vaultFirestore
          .collection('academic_vault')
          .doc(customDocId)
          .set(resourceData);

      final createdDoc = await _vaultFirestore
          .collection('academic_vault')
          .doc(customDocId)
          .get();

      final resource = AcademicResource.fromMap(
        createdDoc.data()!..['id'] = createdDoc.id,
      );

      widget.globalState.addResource(resource);

      if (!mounted) return;

      setState(() {
        _uploadProgress = 1.0;
        _uploadStatus = 'Published successfully!';
      });

      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Resource uploaded successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('UPLOAD ERROR: $e');

      // If Storage succeeded but Firestore failed,
      // clean up the orphaned Storage file.
      if (storagePath != null) {
        try {
          await FirebaseStorage.instanceFor(
            app: Firebase.app(),
            bucket: 'gen-lang-client-0227443307.firebasestorage.app',
          ).ref().child(storagePath).delete();
        } catch (_) {}
      }

      if (!mounted) return;

      setState(() {
        _isUploading = false;
      });

      _showError(_friendlyError(e));
    }
  }

  String _contentType(String fileName) {
    final extension = _extension(fileName);

    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'txt':
        return 'text/plain';
      case 'zip':
        return 'application/zip';
      default:
        return 'application/octet-stream';
    }
  }

  String _friendlyError(Object error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'Firebase permission denied. Check Firestore/Storage rules.';
        case 'unauthenticated':
          return 'Your session expired. Please sign in again.';
        case 'unauthorized':
          return 'You are not authorized to upload this file.';
        case 'canceled':
          return 'Upload was cancelled.';
      }

      return error.message ?? 'Firebase operation failed.';
    }

    return 'Upload failed: $error';
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

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
    final file = _selectedFile;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Upload Resource',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFilePicker(file),

                const SizedBox(height: 20),

                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Resource Title *',
                    hintText: 'e.g. DBMS Unit 1 Complete Notes',
                    prefixIcon: Icon(Icons.title_rounded),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a title';
                    }

                    if (value.trim().length < 5) {
                      return 'Title must be at least 5 characters';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _subjectController,
                  decoration: const InputDecoration(
                    labelText: 'Subject *',
                    hintText: 'e.g. Data Structures',
                    prefixIcon: Icon(Icons.menu_book_rounded),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter the subject';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<ResourceCategory>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                        ),
                        items: ResourceCategory.values.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(
                              category.displayName,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: _isUploading
                            ? null
                            : (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedCategory = value;
                                  });
                                }
                              },
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _selectedSemester,
                        decoration: const InputDecoration(
                          labelText: 'Semester',
                          border: OutlineInputBorder(),
                        ),
                        items: List.generate(8, (index) {
                          final semester = index + 1;

                          return DropdownMenuItem(
                            value: semester,
                            child: Text('Sem $semester'),
                          );
                        }),
                        onChanged: _isUploading
                            ? null
                            : (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedSemester = value;
                                  });
                                }
                              },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: _selectedDepartment,
                  decoration: const InputDecoration(
                    labelText: 'Department',
                    border: OutlineInputBorder(),
                  ),
                  items: _departments.map((department) {
                    return DropdownMenuItem(
                      value: department,
                      child: Text(department, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: _isUploading
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() {
                              _selectedDepartment = value;
                            });
                          }
                        },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Description *',
                    hintText: 'Describe what this resource contains...',
                    prefixIcon: Icon(Icons.description_outlined),
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().length < 10) {
                      return 'Description must be at least 10 characters';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _uploaderController,
                  decoration: const InputDecoration(
                    labelText: 'Your Name',
                    hintText: 'Leave empty to use your profile name',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _tagsController,
                  decoration: const InputDecoration(
                    labelText: 'Tags',
                    hintText: 'Exam, Unit1, Important, Solved',
                    prefixIcon: Icon(Icons.sell_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 24),

                if (_isUploading) ...[
                  Text(
                    _uploadStatus,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),

                  const SizedBox(height: 10),

                  LinearProgressIndicator(
                    value: _uploadProgress,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(20),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    '${(_uploadProgress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 20),
                ],

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: _isUploading ? null : _submitForm,
                    icon: _isUploading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.cloud_upload_rounded),
                    label: Text(
                      _isUploading ? 'Uploading...' : 'Upload & Publish',
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
        ),
      ),
    );
  }

  Widget _buildFilePicker(PlatformFile? file) {
    final hasFile = file != null;

    return InkWell(
      onTap: _isUploading ? null : _pickFile,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: hasFile ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: hasFile ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: hasFile
                    ? const Color(0xFFDBEAFE)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                hasFile
                    ? Icons.check_circle_rounded
                    : Icons.cloud_upload_rounded,
                size: 36,
                color: hasFile
                    ? const Color(0xFF2563EB)
                    : const Color(0xFF64748B),
              ),
            ),

            const SizedBox(height: 14),

            Text(
              hasFile ? file.name : 'Select academic file',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 6),

            Text(
              hasFile
                  ? '${_formatBytes(file.size)} • ${_extension(file.name).toUpperCase()}'
                  : 'PDF, DOC, DOCX, PPT, XLS, TXT or ZIP',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),

            const SizedBox(height: 14),

            OutlinedButton.icon(
              onPressed: _isUploading ? null : _pickFile,
              icon: const Icon(Icons.folder_open_rounded),
              label: Text(hasFile ? 'Change File' : 'Choose File'),
            ),
          ],
        ),
      ),
    );
  }
}
