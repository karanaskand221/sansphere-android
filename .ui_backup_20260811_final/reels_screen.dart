import 'package:flutter/material.dart';

class ReelItem {
  final String title;
  final String type;
  final String college;
  final double price;
  final String author;

  ReelItem({
    required this.title,
    required this.type,
    required this.college,
    required this.price,
    required this.author,
  });
}

class ReelsScreen extends StatefulWidget {
  const ReelsScreen({Key? key}) : super(key: key);

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  final List<ReelItem> localReels = [
    ReelItem(
      title: "DBMS Complete Notes",
      type: "Notes",
      college: "SITRC",
      price: 0.0,
      author: "Karan Askand",
    ),
    ReelItem(
      title: "Java OOPs Cheat Sheet",
      type: "Notes",
      college: "SITRC",
      price: 0.0,
      author: "Admin",
    ),
    ReelItem(
      title: "Compiler Design Guide",
      type: "PYQs",
      college: "SITRC",
      price: 0.0,
      author: "Rahul M.",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          "Academic Reels",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: PageView.builder(
        scrollDirection: Axis.vertical,
        itemCount: localReels.length,
        itemBuilder: (context, index) {
          final item = localReels[index];
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade900),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Chip(label: Text(item.type)),
                const SizedBox(height: 10),
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "College: ${item.college} • Creator: ${item.author}",
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 5),
                Text(
                  "Price: ₹${item.price}",
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
