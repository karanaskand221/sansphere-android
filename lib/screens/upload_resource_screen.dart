import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import '../models/academic_resource.dart';

class UploadResourceScreen extends StatefulWidget {
  const UploadResourceScreen({super.key});

  @override
  State<UploadResourceScreen> createState() => _UploadResourceScreenState();
}

class _UploadResourceScreenState extends State<UploadResourceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _priceController = TextEditingController();

  String _selectedCollege = 'SITRC';
  String _selectedType = 'Notes';
  PlatformFile? _pickedFile;
  bool _isProcessing = false;

  final List<String> _colleges = ['SITRC', 'SIEM', 'SIPS', 'SU'];
  final List<String> _types = ['Notes', 'Code', 'Syllabus', 'PYQ'];

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickDocumentFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: kIsWeb,
    );
    if (result != null) setState(() => _pickedFile = result.files.first);
  }

  void _showFeedback(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _publishResourceAsset() async {
    if (!_formKey.currentState!.validate() || _pickedFile == null) {
      _showFeedback("Please complete all fields and pick a file.", isError: true);
      return;
    }

    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    setState(() => _isProcessing = true);

    try {
      String uniqueFileName = "${DateTime.now().millisecondsSinceEpoch}_${_pickedFile!.name.replaceAll(' ', '_')}";
      Reference storageRef = FirebaseStorage.instance.ref().child("resources/$uniqueFileName");

      String downloadUrl = "";
      if (kIsWeb) {
        downloadUrl = await (await storageRef.putData(_pickedFile!.bytes!)).ref.getDownloadURL();
      } else {
        downloadUrl = await (await storageRef.putFile(File(_pickedFile!.path!))).ref.getDownloadURL();
      }

      final newResource = AcademicResource(
        id: '',
        title: _titleController.text.trim(),
        subtitle: _subtitleController.text.trim().isEmpty ? "Resource for $_selectedCollege" : _subtitleController.text.trim(),
        type: _selectedType == 'PYQ' ? 'PYQs' : _selectedType,
        college: _selectedCollege,
        price: double.tryParse(_priceController.text) ?? 0.0,
        authorUid: currentUser.uid,
        authorName: currentUser.displayName ?? "Student",
        fileUrl: downloadUrl,
        fileName: _pickedFile!.name,
        fileSize: _pickedFile!.size,
        meta: "1 File • ${(_pickedFile!.size / (1024 * 1024)).toStringAsFixed(1)} MB",
      );

      await FirebaseFirestore.instance.collection('academic_vault').add(newResource.toMap());

      if (mounted) {
        _showFeedback("Asset published successfully!");
        Navigator.pop(context); // Go back to feed
      }
    } catch (e) {
      if (mounted) _showFeedback("Upload failed: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Publish Asset"), backgroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(controller: _titleController, decoration: const InputDecoration(labelText: "Title")),
              TextFormField(controller: _subtitleController, decoration: const InputDecoration(labelText: "Subtitle")),
              TextFormField(controller: _priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Price")),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _pickDocumentFile, child: Text(_pickedFile?.name ?? "Pick File")),
              const SizedBox(height: 20),
              _isProcessing 
                ? const CircularProgressIndicator() 
                : ElevatedButton(onPressed: _publishResourceAsset, child: const Text("Publish Now")),
            ],
          ),
        ),
      ),
    );
  }
}
