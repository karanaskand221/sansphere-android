import 'package:flutter/material.dart';
import 'marketplace_feed.dart';

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
  String _attachedFileName = '';
  bool _isUploadingFile = false;

  final List<String> _colleges = ['SITRC', 'SIEM', 'SIPS', 'SU'];
  final List<String> _types = ['Notes', 'PYQ', 'Question Bank'];

  void _simulateFilePicker() async {
    setState(() => _isUploadingFile = true);
    // Simulate real local native asynchronous file parsing response lag
    await Future.delayed(const Duration(milliseconds: 1200));
    setState(() {
      _attachedFileName = "SANSPHERE_DOC_${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}.pdf";
      _isUploadingFile = false;
    });
  }

  void _publishResourceAsset() {
    if (!_formKey.currentState!.validate()) return;
    if (_attachedFileName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please attach a document file (PDF/Image) to upload!"), backgroundColor: Colors.redAccent),
      );
      return;
    }

    double productPrice = double.tryParse(_priceController.text) ?? 10.0;

    // Inject asset into live feed structure pool instantly
    globalResources.insert(
      0,
      Resource(
        title: _titleController.text.trim(),
        type: _selectedType,
        college: _selectedCollege,
        price: productPrice,
        author: "User", // Matches local user dashboard key references
      ),
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [Icon(Icons.cloud_done, color: Colors.green), SizedBox(width: 8), Text("Asset Published!")],
        ),
        content: Text("Your academic file has been distributed onto the SANSPHERE directory grid.\n\n"
            "• Setup Valuation: ₹${productPrice.toStringAsFixed(2)}\n"
            "• Your P2P Share (65%): ₹${(productPrice * 0.65).toStringAsFixed(2)}\n"
            "• Infrastructure Split (35%): ₹${(productPrice * 0.35).toStringAsFixed(2)}"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              Navigator.pop(context); // Return back to Vault screen feed updating changes
            },
            child: const Text("Done"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Publish Study Material", style: TextStyle(fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Document Specifications", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 14),
              
              // Resource Title
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: "Resource Title (e.g., TOC Unit 2 Question Bank)",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.title),
                ),
                validator: (val) => (val == null || val.trim().isEmpty) ? "Title field is mandatory" : null,
              ),
              const SizedBox(height: 16),

              // Pricing Logic
              TextFormField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: "Set Access Price (INR)",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.currency_rupee),
                  helperText: "Calculated Rule: You get 65% per transaction download instantly.",
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return "Please establish resource compensation";
                  if (double.tryParse(val) == null || double.parse(val) < 0) return "Provide a valid amount allocation";
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Meta Selection Dropdown Grid Layout
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedCollege,
                      decoration: InputDecoration(labelText: "Target Campus Branch", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                      items: _colleges.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (val) => setState(() => _selectedCollege = val!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedType,
                      decoration: InputDecoration(labelText: "Document Classification", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                      items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: (val) => setState(() => _selectedType = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // File Attachment Interactive Engine UI
              const Text("Source Material Linkage", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              InkWell(
                onTap: _isUploadingFile ? null : _simulateFilePicker,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _attachedFileName.isEmpty ? Icons.cloud_upload_outlined : Icons.picture_as_pdf,
                        size: 44,
                        color: _attachedFileName.isEmpty ? Colors.grey : Colors.orange,
                      ),
                      const SizedBox(height: 8),
                      _isUploadingFile
                          ? const CircularProgressIndicator.adaptive()
                          : Text(
                              _attachedFileName.isEmpty ? "Tap to attach image, notes data, or PYQ sheet" : _attachedFileName,
                              style: TextStyle(fontWeight: FontWeight.bold, color: _attachedFileName.isEmpty ? Colors.black54 : Colors.green),
                              textAlign: TextAlign.center,
                            ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Action Trigger Button Frame
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.rocket_launch),
                label: const Text("Publish Academic Asset", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                onPressed: _publishResourceAsset,
              ),
            ],
          ),
        ),
      ),
    );
  }
}