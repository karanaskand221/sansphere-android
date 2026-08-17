import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SanCoinTransactionHistoryScreen extends StatelessWidget {
  const SanCoinTransactionHistoryScreen({super.key});

  FirebaseFirestore get _firestore => FirebaseFirestore.instanceFor(
    app: FirebaseFirestore.instance.app,
    databaseId: 'sansphere',
  );

  Query<Map<String, dynamic>> _query(String uid) {
    return _firestore
        .collection('sancoin_transactions')
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true);
  }

  String _formatAmount(num amount) {
    if (amount > 0) {
      return '+${amount.toInt()}';
    }

    return amount.toInt().toString();
  }

  String _formatTimestamp(dynamic value) {
    if (value is! Timestamp) {
      return 'Recently';
    }

    final date = value.toDate();
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);
    final transactionDay = DateTime(date.year, date.month, date.day);

    final difference = today.difference(transactionDay).inDays;

    if (difference == 0) {
      return 'Today • ${_twoDigits(date.hour)}:${_twoDigits(date.minute)}';
    }

    if (difference == 1) {
      return 'Yesterday • ${_twoDigits(date.hour)}:${_twoDigits(date.minute)}';
    }

    return '${_twoDigits(date.day)}/${_twoDigits(date.month)}/${date.year}';
  }

  String _twoDigits(int value) {
    return value.toString().padLeft(2, '0');
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'initial_grant':
        return Icons.card_giftcard_rounded;
      case 'opening_balance':
        return Icons.account_balance_wallet_rounded;
      case 'referral_bonus':
      case 'referral_reward':
        return Icons.people_alt_rounded;
      case 'ad_reward':
        return Icons.ondemand_video_rounded;
      case 'resource_purchase':
        return Icons.shopping_bag_outlined;
      case 'resource_sale':
        return Icons.sell_outlined;
      case 'sancoin_purchase':
        return Icons.add_circle_rounded;
      case 'refund':
        return Icons.currency_exchange_rounded;
      default:
        return Icons.swap_vert_rounded;
    }
  }

  Color _colorForAmount(num amount) {
    if (amount > 0) {
      return const Color(0xFF22C55E);
    }

    if (amount < 0) {
      return const Color(0xFFEF4444);
    }

    return Colors.grey;
  }

  Widget _transactionTile(BuildContext context, Map<String, dynamic> data) {
    final amount = (data['amount'] as num?)?.toInt() ?? 0;
    final type = data['type']?.toString() ?? 'transaction';
    final description =
        data['description']?.toString() ?? 'SanCoin transaction';

    final color = _colorForAmount(amount);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(_iconForType(type), color: color),
        ),
        title: Text(
          description,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            _formatTimestamp(data['createdAt']),
            style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${_formatAmount(amount)} SC',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
            if (data['balanceAfter'] is num)
              Text(
                'Balance ${(data['balanceAfter'] as num).toInt()}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 9),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      appBar: AppBar(
        title: const Text(
          'Transaction History',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: user == null
          ? const Center(child: Text('Please sign in to view transactions.'))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _query(user.uid).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Unable to load transaction history.\n\n'
                        '${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final documents = snapshot.data?.docs ?? [];

                if (documents.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () async {
                      await _firestore.collection('users').doc(user.uid).get();
                    },
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(24),
                      children: [
                        const SizedBox(height: 80),
                        Icon(
                          Icons.receipt_long_rounded,
                          size: 64,
                          color: Colors.grey.shade700,
                        ),
                        const SizedBox(height: 20),
                        const Center(
                          child: Text(
                            'No transactions yet',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            'Your SanCoin activity will appear here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    await _firestore.collection('users').doc(user.uid).get();
                  },
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                    itemCount: documents.length,
                    itemBuilder: (context, index) {
                      return _transactionTile(context, documents[index].data());
                    },
                  ),
                );
              },
            ),
    );
  }
}
