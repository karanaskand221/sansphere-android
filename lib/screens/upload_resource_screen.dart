import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../models/academic_resource.dart';

class UploadResourceScreen extends StatefulWidget {
  const UploadResourceScreen({super.key});

  @override
  State<UploadResourceScreen> createState() => _UploadResourceScreenState();
}

class _UploadResourceScreenState extends State<UploadResourceScreen> {
  static const String _adminEmail = "karanaskand221@gmail.com";
  static const double _otpThreshold = 50.0;

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _priceController = TextEditingController();
  final _docIdController = TextEditingController();

  String _selectedCollege = 'SITRC';
  String _selectedType = 'Notes';
  PlatformFile? _pickedFile;
  bool _isProcessing = false;

  final List<String> _colleges = ['SITRC', 'SIEM', 'SIPS', 'SU'];
  final List<String> _types = ['Notes', 'Code', 'Syllabus', 'PYQ'];

  // Named 'sansphere' database — matches users/mail/otp collections
  final _firestore = FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'sansphere');
  // Default database — matches your existing academic_vault collection
  final _vaultFirestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _priceController.dispose();
    _docIdController.dispose();
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

  Future<bool> _isDocIdTaken(String docId) async {
    final query = await _vaultFirestore
        .collection('academic_vault')
        .where('customDocId', isEqualTo: docId)
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

  Future<void> _publishResourceAsset() async {
    if (!_formKey.currentState!.validate() || _pickedFile == null) {
      _showFeedback("Please complete all fields and pick a file.", isError: true);
      return;
    }

    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final double price = double.tryParse(_priceController.text) ?? 0.0;
    final String docId = _docIdController.text.trim();

    setState(() => _isProcessing = true);

    try {
      // Doc ID uniqueness check
      if (await _isDocIdTaken(docId)) {
        _showFeedback("This Document ID is already in use. Pick another.", isError: true);
        setState(() => _isProcessing = false);
        return;
      }

      // OTP gate for price > 50
      if (price > _otpThreshold) {
        final verified = await _runOtpGate(docId: docId, price: price);
        if (!verified) {
          setState(() => _isProcessing = false);
          return;
        }
      }

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
        customDocId: docId,
        title: _titleController.text.trim(),
        subtitle: _subtitleController.text.trim().isEmpty ? "Resource for $_selectedCollege" : _subtitleController.text.trim(),
        type: _selectedType == 'PYQ' ? 'PYQs' : _selectedType,
        college: _selectedCollege,
        price: price,
        authorUid: currentUser.uid,
        authorName: currentUser.displayName ?? "Student",
        fileUrl: downloadUrl,
        fileName: _pickedFile!.name,
        fileSize: _pickedFile!.size,
        meta: "1 File • ${(_pickedFile!.size / (1024 * 1024)).toStringAsFixed(1)} MB",
      );

      await _vaultFirestore.collection('academic_vault').add(newResource.toMap());

      if (mounted) {
        _showFeedback("Asset published successfully!");
        await _showReferralPopup(docId: docId, title: newResource.title, uid: currentUser.uid);
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) _showFeedback("Upload failed: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<bool> _runOtpGate({required String docId, required double price}) async {
    final rand = Random.secure();
    final String otp = (100000 + rand.nextInt(900000)).toString();
    final requestRef = _firestore.collection('publish_otp_requests').doc();

    await requestRef.set({
      'otp': otp,
      'uid': FirebaseAuth.instance.currentUser?.uid,
      'title': _titleController.text.trim(),
      'customDocId': docId,
      'price': price,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('mail').add({
      'to': [_adminEmail],
      'message': {
        'subject': 'SANSPHERE High-Value Publish OTP',
        'html': '''
          <h3>High-Value Document Publish Request</h3>
          <p><b>Title:</b> ${_titleController.text.trim()}</p>
          <p><b>Doc ID:</b> $docId</p>
          <p><b>Price:</b> ₹${price.toStringAsFixed(2)}</p>
          <p><b>Requesting User UID:</b> ${FirebaseAuth.instance.currentUser?.uid}</p>
          <p><b>OTP:</b> <span style="font-size:20px;font-weight:bold;">$otp</span></p>
          <p>Share this OTP with the user only if you approve this listing.</p>
        ''',
      },
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return false;

    final otpController = TextEditingController();
    final bool? verified = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Admin Approval Required"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Prices above ₹${_otpThreshold.toStringAsFixed(0)} need admin approval. "
                "An OTP has been emailed to the admin — contact them to receive it, then enter it below."),
            const SizedBox(height: 16),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(labelText: "Enter 6-digit OTP", border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final snap = await requestRef.get();
              final data = snap.data();
              if (data != null && data['otp'] == otpController.text.trim() && data['status'] == 'pending') {
                await requestRef.update({'status': 'verified'});
                if (context.mounted) Navigator.pop(context, true);
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Incorrect OTP."), backgroundColor: Colors.redAccent),
                  );
                }
              }
            },
            child: const Text("Verify & Publish"),
          ),
        ],
      ),
    );

    return verified ?? false;
  }

  Future<void> _showReferralPopup({required String docId, required String title, required String uid}) async {
    final String shareText =
        'Check out "$title" on SANSPHERE! Open it with Doc ID: $docId\n'
        'https://sansphere.app/vault/$docId?ref=$uid';

    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Published! 🎉"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Share this link — you'll earn 10 SanCoins the first time someone new opens it through your link."),
            const SizedBox(height: 12),
            SelectableText(shareText, style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
          ElevatedButton(
            onPressed: () async {
              await Share.share(shareText);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("Share"),
          ),
        ],
      ),
    );
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
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: "Document Name"),
                validator: (v) => v == null || v.trim().isEmpty ? "Enter a document name" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _subtitleController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: "Description"),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _docIdController,
                decoration: const InputDecoration(labelText: "Document ID (unique, e.g. DS-NOTES-01)"),
                validator: (v) => v == null || v.trim().isEmpty ? "Enter a unique document ID" : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedCollege,
                decoration: const InputDecoration(labelText: "College"),
                items: _colleges.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (value) => setState(() => _selectedCollege = value!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(labelText: "Resource Type"),
                items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (value) => setState(() => _selectedType = value!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Price (₹1–50 direct, above ₹50 needs admin OTP)"),
                validator: (v) {
                  final n = double.tryParse(v ?? '');
                  if (n == null || n < 1) return "Enter a price of at least ₹1";
                  return null;
                },
              ),
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
