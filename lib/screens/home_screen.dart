import 'package:flutter/material.dart';
import 'resource_detail_screen.dart'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Map<String, dynamic>> _folders = [
    {
      'title': 'Data Structures & Algorithms',
      'filesCount': 14,
      'foldersCount': 4,
      'color': const Color(0xFF6C63FF),
      'category': 'Lecture Notes',
      'uploader': 'Rahul Sharma',
      'price': 10.0,
      'rating': 4.8,
      'downloads': 142,
    },
    {
      'title': 'Engineering Mathematics III',
      'filesCount': 8,
      'foldersCount': 2,
      'color': const Color(0xFFFF6B6B),
      'category': 'PYQ Papers',
      'uploader': 'Sneha Patil',
      'price': 10.0,
      'rating': 4.9,
      'downloads': 210,
    },
    {
      'title': 'Operating Systems & Linux',
      'filesCount': 22,
      'foldersCount': 5,
      'color': const Color(0xFF4ECDC4),
      'category': 'Question Banks',
      'uploader': 'Amit Verma',
      'price': 10.0,
      'rating': 4.5,
      'downloads': 65,
    },
    {
      'title': 'Object Oriented Programming',
      'filesCount': 11,
      'foldersCount': 3,
      'color': const Color(0xFFFFBE0B),
      'category': 'Test Papers',
      'uploader': 'Pooja Kale',
      'price': 10.0,
      'rating': 4.7,
      'downloads': 88,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'SANSPHERE Vault',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: Colors.black87),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.black87),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMiniCategoryCard('Notes', Icons.description_outlined, const Color(0xFFECEBFF), const Color(0xFF6C63FF)),
                _buildMiniCategoryCard('PYQs', Icons.history_edu_outlined, const Color(0xFFFFEAEA), const Color(0xFFFF6B6B)),
                _buildMiniCategoryCard('Banks', Icons.quiz_outlined, const Color(0xFFE2F9F7), const Color(0xFF4ECDC4)),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.only(left: 18.0, top: 20, bottom: 10),
            child: Text(
              'Recent Directories',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              physics: const BouncingScrollPhysics(),
              itemCount: _folders.length,
              itemBuilder: (context, index) {
                final folder = _folders[index];
                return _buildFolderRowItem(context, folder);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniCategoryCard(String label, IconData icon, Color bg, Color tint) {
    return Container(
      width: 105,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: tint, size: 24),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: tint.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFolderRowItem(BuildContext context, Map<String, dynamic> folder) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResourceDetailScreen(item: folder),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FC),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: folder['color'].withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.folder_open_rounded,
                color: folder['color'],
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    folder['title'],
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${folder['filesCount']} files  •  ${folder['foldersCount']} folders',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey.shade400,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}