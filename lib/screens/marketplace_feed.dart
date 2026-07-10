import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'upload_resource_screen.dart';
import 'file_preview_screen.dart';

// Clear Blueprint Model for incoming cloud database items
class ResourceModel {
  final String id;
  final String title;
  final String type;
  final String college;
  final double price;
  final String authorName;
  final String authorUid;
  final String fileUrl;

  ResourceModel({
    required this.id,
    required this.title,
    required this.type,
    required this.college,
    required this.price,
    required this.authorName,
    required this.authorUid,
    required this.fileUrl,
  });

  factory ResourceModel.fromFirestore(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ResourceModel(
      id: doc.id,
      title: data['title'] ?? 'Untitled Resource',
      type: data['type'] ?? 'Notes',
      college: data['college'] ?? 'SITRC',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      authorName: data['authorName'] ?? 'Anonymous Student',
      authorUid: data['authorUid'] ?? '',
      fileUrl: data['fileUrl'] ?? '',
    );
  }
}

// Global Wallet Track Balance fallback constant for UI display consistency
double globalUserWalletBalance = 500.0;

class MarketplaceFeed extends StatefulWidget {
  const MarketplaceFeed({super.key});

  @override
  State<MarketplaceFeed> createState() => _MarketplaceFeedState();
}

class _MarketplaceFeedState extends State<MarketplaceFeed> {
  String _selectedCollegeFilter = 'All';
  String _selectedTypeFilter = 'All';
  
  // Tracks unique document IDs unlocked by the current user
  final Set<String> _unlockedResourceIds = {};

  void _executePurchase(ResourceModel item) {
    if (globalUserWalletBalance < item.price) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [Icon(Icons.warning_amber_rounded, color: Colors.redAccent), SizedBox(width: 8), Text("Insufficient Funds")],
          ),
          content: Text("Your wallet balance (₹${globalUserWalletBalance.toStringAsFixed(2)}) is lower than the asset cost (₹${item.price.toStringAsFixed(2)}).\n\nPlease top up tokens to clear this transaction loop."),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Dismiss")),
          ],
        ),
      );
      return;
    }

    // Process local atomic split configurations
    setState(() {
      globalUserWalletBalance -= item.price;
      _unlockedResourceIds.add(item.id);
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [Icon(Icons.check_circle_rounded, color: Colors.green, size: 26), SizedBox(width: 8), Text("Purchase Cleared!")],
        ),
        content: Text("You have unlocked full secure access to:\n\"${item.title}\"\n\n"
            "• Debited Amount: ₹${item.price.toStringAsFixed(2)}\n"
            "• Creator Split (65%): ₹${(item.price * 0.65).toStringAsFixed(2)}\n"
            "• Infrastructure Fee (35%): ₹${(item.price * 0.35).toStringAsFixed(2)}\n\n"
            "New Wallet Allocation: ₹${globalUserWalletBalance.toStringAsFixed(2)}"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
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
            child: const Text("Open Document View", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Modern soft backdrop accent
      appBar: AppBar(
        title: const Text("The Academic Vault", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blueAccent.withOpacity(0.15)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.account_balance_wallet_rounded, size: 16, color: Colors.blueAccent),
                    const SizedBox(width: 6),
                    Text(
                      "₹${globalUserWalletBalance.toStringAsFixed(2)}",
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blueAccent,
        elevation: 4,
        icon: const Icon(Icons.cloud_upload_rounded, color: Colors.white),
        label: const Text("Publish Material", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const UploadResourceScreen()),
          );
        },
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          // Filter Row 1: Campuses
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Row(
              children: ['All', 'SITRC', 'SIEM', 'SIPS', 'SU'].map((college) {
                final isSelected = _selectedCollegeFilter == college;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(college),
                    selected: isSelected,
                    selectedColor: Colors.blueAccent,
                    labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
                    backgroundColor: Colors.white,
                    side: BorderSide(color: isSelected ? Colors.blueAccent : Colors.grey.withOpacity(0.2)),
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
                  child: ChoiceChip(
                    label: Text(type),
                    selected: isSelected,
                    selectedColor: Colors.orangeAccent[700],
                    labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
                    backgroundColor: Colors.white,
                    side: BorderSide(color: isSelected ? Colors.orangeAccent[700]! : Colors.grey.withOpacity(0.2)),
                    onSelected: (val) => setState(() => _selectedTypeFilter = type),
                  ),
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xEFEFEFEF)),
          
          // Live Global Firebase Sync Pipeline Grid Framework Engine
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('resources').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text("Error fetching streaming parameters infrastructure."));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator.adaptive());
                }

                // Map incoming documents to native resource blueprint arrays
                final allDocs = snapshot.data?.docs ?? [];
                final List<ResourceModel> resources = allDocs.map((doc) => ResourceModel.fromFirestore(doc)).toList();

                // Apply combined active matrix filtering vectors locally
                final filteredList = resources.where((item) {
                  final matchCollege = _selectedCollegeFilter == 'All' || item.college == _selectedCollegeFilter;
                  final matchType = _selectedTypeFilter == 'All' || item.type == _selectedTypeFilter;
                  return matchCollege && matchType;
                }).toList();

                if (filteredList.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.folder_open_outlined, size: 54, color: Colors.grey.withOpacity(0.6)),
                        const SizedBox(height: 12),
                        const Text(
                          "No assets found in this partition stack.", 
                          style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500, fontSize: 15),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 86),
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final item = filteredList[index];
                    // Check ownership rules based on UID strings or purchase vectors
                    final bool isOwned = item.authorUid == currentUid || _unlockedResourceIds.contains(item.id);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black87.withOpacity(0.02),
                            blurRadius: 12,
                            spreadRadius: 1,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.blueAccent.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    "${item.college} • ${item.type.toUpperCase()}",
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueAccent, letterSpacing: 0.5),
                                  ),
                                ),
                                Text(
                                  isOwned ? "Owned" : "By: ${item.authorName}",
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              item.title,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87, height: 1.3),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("ACCESS VALUE", style: TextStyle(fontSize: 10, color: Colors.grey[400], fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                    const SizedBox(height: 2),
                                    Text(
                                      "₹${item.price.toStringAsFixed(2)}",
                                      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Colors.black87),
                                    ),
                                  ],
                                ),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isOwned ? Colors.green[600] : Colors.blueAccent,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  ),
                                  icon: Icon(isOwned ? Icons.menu_book_rounded : Icons.shopping_bag_rounded, size: 18),
                                  label: Text(
                                    isOwned ? "View Vault File" : "Unlock Access",
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}