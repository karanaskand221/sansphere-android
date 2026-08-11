import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final _chatFirestore = FirebaseFirestore.instanceFor(
  app: Firebase.app(),
  databaseId: 'sanvault',
);

String _chatIdFor(String uidA, String uidB) {
  final sorted = [uidA, uidB]..sort();
  return "${sorted[0]}_${sorted[1]}";
}

Future<void> startChatWithUser(
  BuildContext context, {
  required String peerUid,
  required String peerName,
  String? docTitle,
  String? docId,
}) async {
  final me = FirebaseAuth.instance.currentUser;
  if (me == null || me.uid == peerUid) return;

  final chatId = _chatIdFor(me.uid, peerUid);
  final chatRef = _chatFirestore.collection('chats').doc(chatId);
  final snap = await chatRef.get();

  String myName = "Student";
  try {
    final myDoc = await _chatFirestore.collection('users').doc(me.uid).get();
    myName = myDoc.data()?['fullName'] ?? "Student";
  } catch (_) {}

  if (!snap.exists) {
    await chatRef.set({
      'participants': [me.uid, peerUid],
      'participantNames': {me.uid: myName, peerUid: peerName},
      'lastMessage': docTitle != null
          ? "Started a chat about \"$docTitle\""
          : "Chat started",
      'lastMessageAt': FieldValue.serverTimestamp(),
      if (docTitle != null) 'docTitle': docTitle,
      if (docId != null) 'docId': docId,
    });
  }

  if (!context.mounted) return;
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ChatConversationRoom(
        chatId: chatId,
        peerUid: peerUid,
        peerName: peerName,
      ),
    ),
  );
}

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) {
      return const Scaffold(
        body: Center(child: Text("Please log in to view chats.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "SANSPHERE Chats",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _chatFirestore
            .collection('chats')
            .where('participants', arrayContains: myUid)
            .orderBy('lastMessageAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return Center(child: Text('Error: ${snapshot.error}'));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final chats = snapshot.data?.docs ?? [];
          if (chats.isEmpty) {
            return const Center(
              child: Text(
                "No conversations yet — message a seller from a resource page.",
              ),
            );
          }

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, idx) {
              final data = chats[idx].data() as Map<String, dynamic>;
              final participants = List<String>.from(
                data['participants'] ?? [],
              );
              final peerUid = participants.firstWhere(
                (u) => u != myUid,
                orElse: () => '',
              );
              final names = Map<String, dynamic>.from(
                data['participantNames'] ?? {},
              );
              final peerName = names[peerUid] ?? 'User';
              final lastMessage = data['lastMessage'] ?? '';
              final docTitle = data['docTitle'];

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blueAccent.withValues(alpha: 0.1),
                  child: Text(
                    peerName.isNotEmpty ? peerName[0].toUpperCase() : '?',
                  ),
                ),
                title: Text(
                  peerName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  docTitle != null
                      ? "Re: $docTitle • $lastMessage"
                      : lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatConversationRoom(
                      chatId: chats[idx].id,
                      peerUid: peerUid,
                      peerName: peerName,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ChatConversationRoom extends StatefulWidget {
  final String chatId;
  final String peerUid;
  final String peerName;
  const ChatConversationRoom({
    super.key,
    required this.chatId,
    required this.peerUid,
    required this.peerName,
  });

  @override
  State<ChatConversationRoom> createState() => _ChatConversationRoomState();
}

class _ChatConversationRoomState extends State<ChatConversationRoom> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    final me = FirebaseAuth.instance.currentUser;
    if (me == null) return;

    _msgCtrl.clear();
    final chatRef = _chatFirestore.collection('chats').doc(widget.chatId);

    await chatRef.collection('messages').add({
      'text': text,
      'senderUid': me.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await chatRef.set({
      'lastMessage': text,
      'lastMessageAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _showPeerInfo() async {
    final doc = await _chatFirestore
        .collection('users')
        .doc(widget.peerUid)
        .get();
    final data = doc.data();
    final showPhone = data?['showPhoneNumber'] == true;
    final phone = data?['phoneNumber'] ?? '';

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(widget.peerName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("College: ${data?['college'] ?? 'N/A'}"),
            const SizedBox(height: 8),
            Text(
              showPhone && phone.toString().isNotEmpty
                  ? "Phone: $phone"
                  : "Phone number is private",
              style: TextStyle(
                color: showPhone ? Colors.black87 : Colors.grey,
                fontStyle: showPhone ? FontStyle.normal : FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text("Chatting with ${widget.peerName}"),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showPeerInfo,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatFirestore
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('createdAt', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError)
                  return Center(child: Text('Error: ${snapshot.error}'));
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data?.docs ?? [];

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollCtrl.hasClients) {
                    _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
                  }
                });

                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final data = messages[i].data() as Map<String, dynamic>;
                    final isMe = data['senderUid'] == myUid;
                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blueAccent : Colors.grey[200],
                          borderRadius: BorderRadius.circular(12).copyWith(
                            bottomRight: isMe
                                ? const Radius.circular(0)
                                : const Radius.circular(12),
                            bottomLeft: !isMe
                                ? const Radius.circular(0)
                                : const Radius.circular(12),
                          ),
                        ),
                        child: Text(
                          data['text'] ?? '',
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    );
                  },
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
                    decoration: InputDecoration(
                      hintText: "Type something...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blueAccent),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
