import 'package:flutter/material.dart';

class FilePreviewScreen extends StatefulWidget {
  final String documentTitle;
  final String documentCampus;
  
  const FilePreviewScreen({
    super.key, 
    required this.documentTitle, 
    required this.documentCampus
  });

  @override
  State<FilePreviewScreen> createState() => _FilePreviewScreenState();
}

class _FilePreviewScreenState extends State<FilePreviewScreen> {
  int _currentPage = 1;
  final int _totalMockPages = 4;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[800],
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
        title: Text(widget.documentTitle, style: const TextStyle(fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_for_offline_outlined, color: Colors.amberAccent),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Saving encrypted PDF locally to device cache storage...")),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: Container(
        color: Colors.grey[900],
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, color: Colors.white),
              onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
            ),
            Text(
              "Page $_currentPage of $_totalMockPages",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, color: Colors.white),
              onPressed: _currentPage < _totalMockPages ? () => setState(() => _currentPage++) : null,
            ),
          ],
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 12,
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 500, minHeight: 600),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mock Document Header Branding Block
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("CAMPUS CORE: ${widget.documentCampus}", style: const TextStyle(fontSize: 11, color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                      const Icon(Icons.verified_user, color: Colors.green, size: 16),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 12),
                  Text(
                    "Official Academic Transcript - Page $_currentPage",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 20),
                  
                  // Generative Layout Block Rendering Simulated Handwritten/Typed Examination text vectors
                  _buildMockDocumentContentLine(3),
                  _buildMockDocumentContentLine(5),
                  _buildMockDocumentContentLine(2),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blueAccent.withOpacity(0.2)),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.insights, color: Colors.blueAccent, size: 32),
                          SizedBox(height: 6),
                          Text("[ Reference Diagram / Engineering Proof Sheet ]", style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildMockDocumentContentLine(4),
                  _buildMockDocumentContentLine(6),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMockDocumentContentLine(int paragraphsCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(paragraphsCount, (index) => Padding(
          padding: const EdgeInsets.only(bottom: 4.0),
          child: Container(
            width: double.infinity,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        )),
      ),
    );
  }
}