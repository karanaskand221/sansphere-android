import 'package:flutter/material.dart';
import 'marketplace_feed.dart';

class SocialReel {
  final String authorName;
  final String description;
  final String attachedResourceTitle;
  final Color backgroundTheme;
  SocialReel({required this.authorName, required this.description, required this.attachedResourceTitle, required this.backgroundTheme});
}

class ReelsScreen extends StatefulWidget {
  const ReelsScreen({super.key});
  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  final List<SocialReel> dummyReels = [
    SocialReel(authorName: "Karan", description: "IMP Questions for Math Unit 3! Passed with this last night 🔥", attachedResourceTitle: "Engineering Math - III", backgroundTheme: Colors.indigo),
    SocialReel(authorName: "Admin", description: "Data Structures complete premium question banks attached.", attachedResourceTitle: "Data Structures PYQ 2025", backgroundTheme: Colors.blueGrey),
  ];

  void _showAttachedAsset(String title) {
    // Find item details from our live market list
    Resource item = globalResources.firstWhere((r) => r.title == title, 
        orElse: () => Resource(title: title, type: "Notes", college: "SITRC", price: 10.0, author: "System"));

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(label: Text(item.type), backgroundColor: Colors.blueAccent.withOpacity(0.15)),
                Text("₹${item.price.toInt()}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
              ],
            ),
            const SizedBox(height: 12),
            Text(item.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text("College: ${item.college} • Creator: ${item.author}", style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48), backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Redirected to main Vault panel to purchase item.")));
              },
              child: const Text("View File inside Vault Marketplace"),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView.builder(
        scrollDirection: Axis.vertical,
        itemCount: dummyReels.length,
        itemBuilder: (context, i) {
          final reel = dummyReels[i];
          return Container(
            color: reel.backgroundTheme,
            child: Stack(
              children: [
                // Simulated Video Content Graphic
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.play_circle_fill, size: 80, color: Colors.white60),
                      const SizedBox(height: 12),
                      Text("[ Preview Clip by @${reel.authorName} ]", style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
                // Author description card alignment
                Positioned(
                  bottom: 40,
                  left: 16,
                  right: 90,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("@${reel.authorName}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 6),
                      Text(reel.description, style: const TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                // Floating link trigger configuration
                Positioned(
                  bottom: 40,
                  right: 16,
                  child: FloatingActionButton.extended(
                    heroTag: "btn_$i",
                    backgroundColor: Colors.amberAccent,
                    foregroundColor: Colors.black,
                    icon: const Icon(Icons.cloud_download),
                    label: const Text("📥 View File"),
                    onPressed: () => _showAttachedAsset(reel.attachedResourceTitle),
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}