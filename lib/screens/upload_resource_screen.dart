import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb verification
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart'; // Handles real native local file picking

class UploadResourceScreen extends StatefulWidget {
  const UploadResourceScreen({super.key});

  @override
  State<UploadResourceScreen> createState() => _UploadResourceScreenState();
}

class _UploadResourceScreenState extends State<UploadResourceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();

  String _selectedCollege = 'SITRC';
  String _selectedType = 'Notes';
  
  // Real file pipeline trackers
  PlatformFile? _pickedFile;
  bool _isProcessing = false;

  final List<String> _colleges = ['SITRC', 'SIEM', 'SIPS', 'SU'];
  final List<String> _types = ['Notes', 'PYQ', 'Question Bank'];

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  // Pick a real file from user storage
  Future<void> _pickDocumentFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        withData: kIsWeb, // Required byte mapping for web target architecture
      );

      if (result != null) {
        setState(() {
          _pickedFile = result.files.first;
        });
      }
    } catch (e) {
      debugPrint("File picker error: $e");
    }
  }

  // Upload to Storage and publish schema layout details onto Firestore
  Future<void> _publishResourceAsset() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please attach an actual document file (PDF/Image) to upload!"), 
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Authentication expired. Please log back in.")),
      );
      return;
    }

    setState(() => _isProcessing = true);
    double productPrice = double.tryParse(_priceController.text) ?? 10.0;

    try {
      // 1. Generate unique file directory identifier string inside Cloud Storage
      String uniqueFileName = "${DateTime.now().millisecondsSinceEpoch}_${_pickedFile!.name}";
      Reference storageRef = FirebaseStorage.instance.ref().child("resources/$uniqueFileName");

      String downloadUrl = "";
      
      // 2. Upload file bytes or system path dependent on platform architecture
      if (kIsWeb) {
        UploadTask uploadTask = storageRef.putData(_pickedFile!.bytes!);
        TaskSnapshot snapshot = await uploadTask;
        downloadUrl = await snapshot.ref.getDownloadURL();
      } else {
        UploadTask uploadTask = storageRef.putFile(File(_pickedFile!.path!));
        TaskSnapshot snapshot = await uploadTask;
        downloadUrl = await snapshot.ref.getDownloadURL();
      }

      // 3. Write data map straight into global Firestore directory list collection
      await FirebaseFirestore.instance.collection('resources').add({
        'title': _titleController.text.trim(),
        'type': _selectedType,
        'college': _selectedCollege,
        'price': productPrice,
        'authorUid': currentUser.uid,
        'authorName': currentUser.displayName ?? "Anonymous Student",
        'fileUrl': downloadUrl,
        'fileName': _pickedFile!.name,
        'fileSize': _pickedFile!.size,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      // Elegant Completion Success Alert Layout Dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
              SizedBox(width: 10),
              Text("Asset Published!", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            "Your academic file has been successfully uploaded and is visible to the network community.\n\n"
            "• Value Setup: ₹${productPrice.toStringAsFixed(2)}\n"
            "• Your P2P Share (65%): ₹${(productPrice * 0.65).toStringAsFixed(2)}\n"
            "• Platform Fee (35%): ₹${(productPrice * 0.35).toStringAsFixed(2)}",
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx); // Close dialog
                Navigator.pop(context); // Pop back smoothly to feed
              },
              child: const Text("Done", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            )
          ],
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload execution process failed: $error"), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Modern clean background canvas
      appBar: AppBar(
        title: const Text("Publish Study Material", style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Premium card enclosing input data segments
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, spreadRadius: 2, offset: const Offset(0, 4))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("DOCUMENT DETAILS", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blueAccent, letterSpacing: 1.1)),
                    const SizedBox(height: 18),
                    
                    // Title Field
                    TextFormField(
                      controller: _titleController,
                      decoration: _buildInputDecoration("Resource Title (e.g., TOC Unit 2 Notes)", Icons.title_rounded),
                      validator: (val) => (val == null || val.trim().isEmpty) ? "Title field is mandatory" : null,
                    ),
                    const SizedBox(height: 18),

                    // Pricing Field
                    TextFormField(
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: _buildInputDecoration("Set Access Price (INR)", Icons.currency_rupee_rounded).copyWith(
                        helperText: "Payout Rule: Earn 65% per transaction download instantly.",
                        helperStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return "Please establish resource compensation";
                        if (double.tryParse(val) == null || double.parse(val) < 0) return "Provide a valid amount allocation";
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),

                    // Campus Dropdown selectors split row
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedCollege,
                            decoration: _buildInputDecoration("Target Campus", Icons.school_outlined),
                            items: _colleges.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                            onChanged: (val) => setState(() => _selectedCollege = val!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedType,
                            decoration: _buildInputDecoration("Classification", Icons.class_outlined),
                            items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                            onChanged: (val) => setState(() => _selectedType = val!),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Interactive Upload Box Container Panel
              const Text("SOURCE MATERIAL LINKAGE", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54, letterSpacing: 1.1)),
              const SizedBox(height: 12),
              
              InkWell(
                onTap: _isProcessing ? null : _pickDocumentFile,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                  decoration: BoxDecoration(
                    color: _pickedFile == null ? const Color(0xFFF1F5F9) : Colors.green.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _pickedFile == null ? Colors.grey.withOpacity(0.3) : Colors.green.withOpacity(0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _pickedFile == null ? Icons.cloud_upload_rounded : Icons.picture_as_pdf_rounded,
                        size: 48,
                        color: _pickedFile == null ? Colors.blueAccent : Colors.green,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _pickedFile == null ? "Tap to attach document sheet" : _pickedFile!.name,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _pickedFile == null ? Colors.black54 : Colors.green[700]),
                        textAlign: TextAlign.center,
                      ),
                      if (_pickedFile != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          "${(_pickedFile!.size / (1024 * 1024)).toStringAsFixed(2)} MB",
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 35),

              // Action Publish Frame Trigger Button
              _isProcessing
                  ? const Center(child: CircularProgressIndicator())
                  : Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(colors: [Colors.blueAccent, Colors.lightBlue]),
                      ),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 54),
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        icon: const Icon(Icons.rocket_launch_rounded, color: Colors.white),
                        label: const Text("Publish Academic Asset", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        onPressed: _publishResourceAsset,
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String labelText, IconData icon) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
      prefixIcon: Icon(icon, color: Colors.blueAccent.withOpacity(0.7)),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.withOpacity(0.15))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5)),
    );
  }
}