import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../global_state.dart';
import '../models/academic_resource.dart';
import 'resource_detail_screen.dart';


final _chatFirestore = FirebaseFirestore.instanceFor(
  app: Firebase.app(),
  databaseId: 'sansphere',
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
  required GlobalState globalState,
}) async {
  final me = FirebaseAuth.instance.currentUser;

  if (me == null) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please log in first.')));
    }
    return;
  }

  if (me.uid == peerUid) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot chat with yourself.')),
      );
    }
    return;
  }

  try {
    final chatId = _chatIdFor(me.uid, peerUid);
    final chatRef = _chatFirestore.collection('chats').doc(chatId);

    String myName = 'Student';

    try {
      final myDoc = await _chatFirestore.collection('users').doc(me.uid).get();

      final data = myDoc.data();

      if (data != null) {
        myName = data['fullName']?.toString() ?? 'Student';
      }
    } catch (e) {
      debugPrint('Could not load current user profile: $e');
    }

    await chatRef.set({
      'participants': [me.uid, peerUid],
      'participantNames': {me.uid: myName, peerUid: peerName},
      'lastMessage': docTitle != null
          ? 'Started a chat about "$docTitle"'
          : 'Chat started',
      'lastMessageAt': FieldValue.serverTimestamp(),
      if (docTitle != null) 'docTitle': docTitle,
      if (docId != null) 'docId': docId,
    }, SetOptions(merge: true));

    if (!context.mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatConversationRoom(
          chatId: chatId,
          peerUid: peerUid,
          peerName: peerName,
          globalState: globalState,
        ),
      ),
    );
  } catch (e) {
    debugPrint('START CHAT FAILED: $e');

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Could not start chat: $e'),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 6),
      ),
    );
  }
}

class ChatListScreen extends StatelessWidget {
  final GlobalState globalState;

  const ChatListScreen({
    super.key,
    required this.globalState,
  });

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
                      globalState: globalState,
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
  final GlobalState globalState;
  const ChatConversationRoom({
    super.key,
    required this.chatId,
    required this.peerUid,
    required this.peerName,
    required this.globalState,
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


  Widget _buildResourceMessage(
    BuildContext context,
    Map<String, dynamic> data,
    bool isMe,
  ) {
    final resourceId = data['resourceId']?.toString().trim() ?? '';
    final title = data['resourceTitle']?.toString().trim() ?? '';
    final subject = data['resourceSubject']?.toString().trim() ?? '';
    final uploader = data['resourceUploaderName']?.toString().trim() ?? '';
    final priceValue = data['resourcePrice'];

    final price = priceValue is num
        ? priceValue.toDouble()
        : double.tryParse(priceValue?.toString() ?? '') ?? 0;

    return Container(
      width: MediaQuery.of(context).size.width * 0.78,
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFFEFF6FF) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMe
              ? const Color(0xFFBFDBFE)
              : const Color(0xFFE2E8F0),
        ),
        boxShadow: const [
          BoxShadow(
            blurRadius: 8,
            offset: Offset(0, 2),
            color: Color(0x10000000),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.description_rounded,
                  color: Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 11),
              const Expanded(
                child: Text(
                  'Shared Resource',
                  style: TextStyle(
                    color: Color(0xFF2563EB),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            title.isNotEmpty ? title : 'Academic Resource',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),

          if (subject.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              subject,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
              ),
            ),
          ],

          if (uploader.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Uploaded by $uploader',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
              ),
            ),
          ],

          const SizedBox(height: 10),

          Row(
            children: [
              Icon(
                price > 0
                    ? Icons.monetization_on_rounded
                    : Icons.card_giftcard_rounded,
                size: 17,
                color: const Color(0xFF2563EB),
              ),
              const SizedBox(width: 5),
              Text(
                price > 0
                    ? '${price.toStringAsFixed(0)} SanCoins'
                    : 'Free',
                style: const TextStyle(
                  color: Color(0xFF2563EB),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: resourceId.isEmpty
                  ? null
                  : () => _openSharedResource(
                        context,
                        resourceId,
                      ),
              icon: const Icon(
                Icons.open_in_new_rounded,
                size: 17,
              ),
              label: const Text('View Resource'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2563EB),
                side: const BorderSide(
                  color: Color(0xFFBFDBFE),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openSharedResource(
    BuildContext context,
    String resourceId,
  ) async {
    try {
      final cleanId = resourceId.trim();

      if (cleanId.isEmpty) {
        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This resource cannot be opened.'),
          ),
        );
        return;
      }

      AcademicResource? resource;

      // First use the resources already loaded by the application's
      // shared GlobalState.
      for (final item in widget.globalState.resources) {
        if (item.id.trim() == cleanId ||
            item.customDocId.trim() == cleanId) {
          resource = item;
          break;
        }
      }

      // Fallback to the real Academic Vault database.
      if (resource == null) {
        final vaultFirestore = FirebaseFirestore.instanceFor(
          app: Firebase.app(),
          databaseId: 'sanvault',
        );

        final doc = await vaultFirestore
            .collection('academic_vault')
            .doc(cleanId)
            .get();

        if (doc.exists && doc.data() != null) {
          resource = AcademicResource.fromMap(
            doc.data()!,
            doc.id,
          );
        }
      }

      if (!context.mounted) return;

      if (resource == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'This resource is no longer available.',
            ),
          ),
        );
        return;
      }

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResourceDetailScreen(
            resource: resource!,
            globalState: widget.globalState,
          ),
        ),
      );
    } catch (e) {
      debugPrint(
        'Could not open shared resource: $e',
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not open this resource.',
          ),
        ),
      );
    }
  }

  Future<void> _showPeerInfo() async {
    try {
      final functions = FirebaseFunctions.instanceFor(
        app: Firebase.app(),
        region: 'us-central1',
      );

      final result = await functions.httpsCallable('getChatPeerInfo').call(
        <String, dynamic>{'peerUid': widget.peerUid},
      );

      final data = result.data;

      if (data is! Map) {
        throw Exception('Invalid peer profile response.');
      }

      final showPhone = data['showPhoneNumber'] == true;
      final phone = data['phoneNumber']?.toString() ?? '';
      final college = data['college']?.toString() ?? '';

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(widget.peerName),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("College: ${college.isNotEmpty ? college : 'N/A'}"),
              const SizedBox(height: 8),
              Text(
                showPhone && phone.isNotEmpty
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
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Unable to load profile information.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to load profile information.')),
      );
    }
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
                    final data =
                        messages[i].data() as Map<String, dynamic>;
                    final isMe = data['senderUid'] == myUid;
                    final isResource = data['type'] == 'resource';

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: isResource
                          ? _buildResourceMessage(
                              context,
                              data,
                              isMe,
                            )
                          : Container(
                              margin:
                                  const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.75,
                              ),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? Colors.blueAccent
                                    : Colors.grey[200],
                                borderRadius:
                                    BorderRadius.circular(12).copyWith(
                                  bottomRight: isMe
                                      ? const Radius.circular(0)
                                      : const Radius.circular(12),
                                  bottomLeft: !isMe
                                      ? const Radius.circular(0)
                                      : const Radius.circular(12),
                                ),
                              ),
                              child: Text(
                                data['text']?.toString() ?? '',
                                style: TextStyle(
                                  color:
                                      isMe ? Colors.white : Colors.black87,
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
