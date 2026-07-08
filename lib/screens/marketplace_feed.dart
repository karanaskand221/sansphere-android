import 'package:flutter/material.dart';
import 'upload_resource_screen.dart';
import 'file_preview_screen.dart';

// Live Global Resource Repository Pool accessed by UploadResourceScreen
class Resource {
  final String title;
  final String type;
  final String college;
  final double price;
  final String author;

  Resource({
    required this.title,
    required this.type,
    required this.college,
    required this.price,
    required this.author,
  });
}

// Seed data matching Sandip University campuses and classifications
final List<Resource> globalResources = [
  Resource(
    title: "Engineering Mathematics-III Full Handwritten Notes",
    type: "Notes",
    college: "SITRC",
    price: 49.0,
    author: "Rahul_Sharma",
  ),
  Resource(
    title: "Data Structures & Algorithms 2024 End-Sem PYQ Solutions",
    type: "PYQ",
    college: "SITRC",
    price: 25.0,
    author: "Amit_Verma",
  ),
  Resource(
    title: "Pharmacognosy-I Question Bank (Unit 1 to 5)",
    type: "Question Bank",
    college: "SIPS",
    price: 30.0,
    author: "Pooja_Patil",
  ),
  Resource(
    title: "MBA Marketing Management Case Study Sheet",
    type: "Notes",
    college: "SU",
    price: 15.0,
    author: "Neha_Joshi",
  ),
];

// Mock Global Wallet Tracking Balance
double globalUserWalletBalance = 500.0;

class MarketplaceFeed extends StatefulWidget {
  const MarketplaceFeed({super.key});

  @override
  State<MarketplaceFeed> createState() => _MarketplaceFeedState();
}

class _MarketplaceFeedState extends State<MarketplaceFeed> {
  String _selectedCollegeFilter = 'All';
  String _selectedTypeFilter = 'All';
  
  // Tracks titles of resources the local user has purchased or unlocked
  final Set<String> _unlockedResourceTitles = {};

  void _executePurchase(Resource item) {
    if (globalUserWalletBalance < item.price) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [Icon(Icons.warning_amber_rounded, color: Colors.red), SizedBox(width: 8), Text("Insufficient Funds")],
          ),
          content: Text("Your wallet balance (₹${globalUserWalletBalance.toStringAsFixed(2)}) is lower than the asset cost (₹${item.price.toStringAsFixed(2)}).\n\nPlease add tokens to your SANSPHERE Wallet split."),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Dismiss")),
          ],
        ),
      );
      return;
    }

    // Process split distributions
    setState(() {
      globalUserWalletBalance -= item.price;
      _unlockedResourceTitles.add(item.title);
    });

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [Icon(Icons.check_circle, color: Colors.green), SizedBox(width: 8), Text("Purchase Successful!")],
        ),
        content: Text("You have unlocked full access to:\n\"${item.title}\"\n\n"
            "• Debited Amount: ₹${item.price.toStringAsFixed(2)}\n"
            "• Author P2P Share (65%): ₹${(item.price * 0.65).toStringAsFixed(2)}\n"
            "• Infrastructure Fee (35%): ₹${(item.price * 0.35).toStringAsFixed(2)}\n\n"
            "Remaining Wallet Balance: ₹${globalUserWalletBalance.toStringAsFixed(2)}"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Instantly navigate into document preview sheet after purchase
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FilePreviewScreen(
                    documentTitle: item.title,
                    documentCampus: item.college,
                  ),
                ),
              );
            },
            child: const Text("Open Document View"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Apply combined live filtering vectors
    final filteredList = globalResources.where((item) {
      final matchCollege = _selectedCollegeFilter == 'All' || item.college == _selectedCollegeFilter;
      final matchType = _selectedTypeFilter == 'All' || item.type == _selectedTypeFilter;
      return matchCollege && matchType;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("The Academic Vault", style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Chip(
              backgroundColor: Colors.blueAccent.withOpacity(0.1),
              avatar: const Icon(Icons.account_balance_wallet, size: 16, color: Colors.blueAccent),
              label: Text(
                "₹${globalUserWalletBalance.toStringAsFixed(2)}",
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent),
              ),
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.cloud_upload),
        label: const Text("Publish Material"),
        onPressed: () async {
          // Navigate to upload form and update screen feed state when coming back
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const UploadResourceScreen()),
          );
          setState(() {});
        },
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Row 1: Campuses
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
            child: Row(
              children: ['All', 'SITRC', 'SIEM', 'SIPS', 'SU'].map((college) {
                final isSelected = _selectedCollegeFilter == college;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(college),
                    selected: isSelected,
                    selectedColor: Colors.blueAccent.withOpacity(0.2),
                    checkmarkColor: Colors.blueAccent,
                    onSelected: (val) => setState(() => _selectedCollegeFilter = college),
                  ),
                );
              }).toList(),
            ),
          ),
          
          // Filter Row 2: Category Types
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Row(
              children: ['All', 'Notes', 'PYQ', 'Question Bank'].map((type) {
                final isSelected = _selectedTypeFilter == type;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(type),
                    selected: isSelected,
                    selectedColor: Colors.orangeAccent.withOpacity(0.2),
                    checkmarkColor: Colors.orange,
                    onSelected: (val) => setState(() => _selectedTypeFilter = type),
                  ),
                );
              }).toList(),
            ),
          ),
          
          const Divider(height: 20),
          
          // Resource Marketplace Grid Feed
          Expanded(
            child: filteredList.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.folder_open_outlined, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text("No matching resources found for this campus partition.", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final item = filteredList[index];
                      final bool isOwned = item.author == "User" || _unlockedResourceTitles.contains(item.title);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.blueAccent.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      "${item.college} • ${item.type}",
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                                    ),
                                  ),
                                  Text(
                                    "By: ${item.author == 'User' ? 'You' : item.author}",
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                item.title,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("ACCESS EVALUATION", style: TextStyle(fontSize: 10, color: Colors.grey[500], letterSpacing: 0.5)),
                                      Text(
                                        "₹${item.price.toStringAsFixed(2)}",
                                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black),
                                      ),
                                    ],
                                  ),
                                  
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isOwned ? Colors.green : Colors.blueAccent,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                    ),
                                    icon: Icon(isOwned ? Icons.menu_book : Icons.shopping_bag_outlined, size: 18),
                                    label: Text(
                                      isOwned ? "View Content" : "Unlock File",
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    onPressed: () {
                                      if (isOwned) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => FilePreviewScreen(
                                              documentTitle: item.title,
                                              documentCampus: item.college,
                                            ),
                                          ),
                                        );
                                      } else {
                                        _executePurchase(item);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}