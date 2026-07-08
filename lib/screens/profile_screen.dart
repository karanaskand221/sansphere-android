import 'package:flutter/material.dart';
import '../main.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    double myEarnings = creatorEarnings["User"] ?? 0.0;

    return Scaffold(
      appBar: AppBar(title: const Text("SANSPHERE Wallet & Profile", style: TextStyle(fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Meta Header Card
            Card(
              color: Colors.blueAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    const CircleAvatar(radius: 32, backgroundColor: Colors.white, child: Icon(Icons.person, size: 36, color: Colors.blueAccent)),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Sandip University Student", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        Text("Class Account ID: @student2026", style: TextStyle(color: Colors.white.withOpacity(0.8))),
                      ],
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text("Financial Split Dashboard", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            
            // Grid metrics mapping the 65/35 math rule engine
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                _buildWalletCard("Available Cash", "₹${currentUserWallet.toStringAsFixed(2)}", Icons.account_balance_wallet, Colors.teal),
                _buildWalletCard("My Document Sales", "₹${myEarnings.toStringAsFixed(2)}", Icons.monetization_on, Colors.purple),
                _buildWalletCard("Unlocked Assets", "${purchasedResourceTitles.length} Files", Icons.folder_shared, Colors.orange),
                _buildWalletCard("Platform Processing Pool", "₹${platformProcessingPool.toStringAsFixed(2)}", Icons.admin_panel_settings, Colors.blueGrey),
              ],
            ),
            
            const SizedBox(height: 24),
            Card(
              color: Colors.grey[100],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blueAccent),
                        SizedBox(width: 8),
                        Text("SANSPHERE Ecosystem Protocol Rules", style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Divider(),
                    Text(
                      "All resources hosted under Sandip Academic parameters obey a strict split system: 65% of set transaction pricing is automatically credited to the original author. The remaining 35% funds computational transaction server processing.",
                      style: TextStyle(fontSize: 13, color: Colors.black87),
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildWalletCard(String label, String balance, IconData icon, Color designColor) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Colors.grey[200]!)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: designColor, size: 28),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(balance, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            )
          ],
        ),
      ),
    );
  }
}