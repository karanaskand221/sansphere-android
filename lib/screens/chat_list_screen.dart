import 'package:flutter/material.dart';

class ChatMessage {
  final String text;
  final bool isMe;
  ChatMessage({required this.text, required this.isMe});
}

// Global mockup database array structure for messages
Map<String, List<ChatMessage>> globalConversationLogs = {
  "Karan": [
    ChatMessage(text: "Hey, can I get a discount on the Math unit notes?", isMe: true),
    ChatMessage(text: "The price is already set at ₹10, bro! Very cheap.", isMe: false),
  ],
  "Admin": [
    ChatMessage(text: "Are the complete PYQs included in your file?", isMe: true),
  ]
};

void initializeChatWithUser(String username) {
  if (!globalConversationLogs.containsKey(username)) {
    globalConversationLogs[username] = [
      ChatMessage(text: "Hi, I am interested in purchasing your notes resource!", isMe: true)
    ];
  }
}

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});
  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  Widget build(BuildContext context) {
    final activeChats = globalConversationLogs.keys.toList();

    return Scaffold(
      appBar: AppBar(title: const Text("SANSPHERE Chats", style: TextStyle(fontWeight: FontWeight.bold))),
      body: activeChats.isEmpty
          ? const Center(child: Text("No negotiation sessions active."))
          : ListView.builder(
              itemCount: activeChats.length,
              itemBuilder: (context, idx) {
                String peer = activeChats[idx];
                var messages = globalConversationLogs[peer]!;
                return ListTile(
                  leading: CircleAvatar(backgroundColor: Colors.blueAccent.withOpacity(0.1), child: Text(peer[0])),
                  title: Text(peer, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(messages.last.text, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ChatConversationRoom(recipient: peer))).then((value) => setState(() {}));
                  },
                );
              },
            ),
    );
  }
}

class ChatConversationRoom extends StatefulWidget {
  final String recipient;
  const ChatConversationRoom({super.key, required this.recipient});
  @override
  State<ChatConversationRoom> createState() => _ChatConversationRoomState();
}

class _ChatConversationRoomState extends State<ChatConversationRoom> {
  final _msgCtrl = TextEditingController();

  void _sendMessage() {
    String txt = _msgCtrl.text.trim();
    if (txt.isEmpty) return;

    setState(() {
      globalConversationLogs[widget.recipient]!.add(ChatMessage(text: txt, isMe: true));
      _msgCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    var history = globalConversationLogs[widget.recipient] ?? [];

    return Scaffold(
      appBar: AppBar(title: Text("Chatting with ${widget.recipient}")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: history.length,
              itemBuilder: (context, i) {
                final message = history[i];
                return Align(
                  alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: message.isMe ? Colors.blueAccent : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12).copyWith(
                        bottomRight: message.isMe ? const Radius.circular(0) : const Radius.circular(12),
                        bottomLeft: !message.isMe ? const Radius.circular(0) : const Radius.circular(12),
                      ),
                    ),
                    child: Text(
                      message.text,
                      style: TextStyle(color: message.isMe ? Colors.white : Colors.black87),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8.0),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    decoration: InputDecoration(hintText: "Type something...", border: OutlineInputBorder(borderRadius: BorderRadius.circular(24))),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(icon: const Icon(Icons.send, color: Colors.blueAccent), onPressed: _sendMessage),
              ],
            ),
          )
        ],
      ),
    );
  }
}