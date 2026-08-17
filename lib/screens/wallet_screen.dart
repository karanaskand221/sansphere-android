import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'sancoin_transaction_history_screen.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  RewardedAd? _rewardedAd;
  bool _isRewardedAdLoading = false;
  bool _isRewardingAd = false;

  // Google's official Android rewarded TEST ad unit.
  // Replace with your own AdMob rewarded ad unit before production.
  static const String _rewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';

  final FirebaseFirestore _firestore = FirebaseFirestore.instanceFor(
    app: FirebaseFirestore.instance.app,
    databaseId: 'sansphere',
  );

  Map<String, dynamic>? _userData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadWallet();
  }

  Future<void> _loadWallet() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() => _loading = false);
      }
      return;
    }

    try {
      final snapshot = await _firestore.collection('users').doc(user.uid).get();

      if (!mounted) return;

      setState(() {
        _userData = snapshot.data();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    }
  }

  int get _sanCoins {
    final value = _userData?['sanCoins'];
    if (value is num) return value.toInt();
    return 0;
  }

  int get _earnedCoins {
    final value = _userData?['earnedCoins'];
    if (value is num) return value.toInt();
    return 0;
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
    bool enabled = true,
  }) {
    final color = iconColor ?? const Color(0xFF2563EB);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: enabled ? 0.06 : 0.035),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: enabled ? 0.13 : 0.06),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: enabled ? color : Colors.grey),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: enabled ? null : Colors.grey,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: enabled ? Colors.grey.shade500 : Colors.grey.shade700,
            ),
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 15,
          color: enabled ? Colors.grey : Colors.grey.shade700,
        ),
        onTap: enabled ? onTap : null,
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 21, color: const Color(0xFF60A5FA)),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _packageCard({
    required int coins,
    required String price,
    bool popular = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: popular
              ? const Color(0xFF2563EB).withValues(alpha: 0.6)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.stars_rounded, color: Color(0xFFF59E0B)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$coins SanCoins',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                if (popular)
                  const Padding(
                    padding: EdgeInsets.only(top: 3),
                    child: Text(
                      'POPULAR',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF60A5FA),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Text(
            price,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  void _loadRewardedAd() {
    if (_isRewardedAdLoading || _rewardedAd != null) {
      return;
    }

    setState(() {
      _isRewardedAdLoading = true;
    });

    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }

          setState(() {
            _rewardedAd = ad;
            _isRewardedAdLoading = false;
          });

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (RewardedAd ad) {
              ad.dispose();

              if (!mounted) {
                return;
              }

              setState(() {
                _rewardedAd = null;
                _isRewardedAdLoading = false;
              });

              // Load the next ad for the next visit.
              _loadRewardedAd();
            },
            onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
              ad.dispose();

              if (!mounted) {
                return;
              }

              setState(() {
                _rewardedAd = null;
                _isRewardedAdLoading = false;
              });

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Unable to show the rewarded ad. Please try again.',
                  ),
                ),
              );

              _loadRewardedAd();
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          if (!mounted) {
            return;
          }

          setState(() {
            _rewardedAd = null;
            _isRewardedAdLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Rewarded ad is not available right now. Please try again.',
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _watchAdAndEarn() async {
    if (_isRewardingAd) {
      return;
    }

    final ad = _rewardedAd;

    if (ad == null) {
      _loadRewardedAd();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Loading a rewarded ad. Please tap again in a moment.'),
        ),
      );

      return;
    }

    setState(() {
      _isRewardingAd = true;
      _rewardedAd = null;
    });

    bool rewardEarned = false;

    ad.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) async {
        rewardEarned = true;

        final user = FirebaseAuth.instance.currentUser;

        if (user == null) {
          return;
        }

        try {
          final rewardId =
              '${user.uid}_${DateTime.now().microsecondsSinceEpoch}';

          final result = await FirebaseFunctions.instance
              .httpsCallable('rewardAd')
              .call({'rewardId': rewardId});

          final data = result.data is Map
              ? Map<String, dynamic>.from(result.data as Map)
              : <String, dynamic>{};

          if (!mounted) {
            return;
          }

          final rewardAmount = (data['reward'] as num?)?.toInt() ?? 10;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('🎉 You earned $rewardAmount SanCoins!')),
          );
        } on FirebaseFunctionsException catch (e) {
          if (!mounted) {
            return;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.message ?? 'Unable to claim the ad reward.'),
            ),
          );
        } catch (_) {
          if (!mounted) {
            return;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to claim the ad reward. Please try again.'),
            ),
          );
        }
      },
    );

    // Prevent a stuck loading state even if the ad lifecycle
    // completes without returning through the callback above.
    if (mounted) {
      setState(() {
        _isRewardingAd = false;
      });
    }

    if (!rewardEarned) {
      // Reward will only be credited from onUserEarnedReward.
    }
  }

  @override
  void dispose() {
    _rewardedAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      appBar: AppBar(
        title: const Text(
          'Wallet',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadWallet,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ========================================================
                    // SANCOIN BALANCE
                    // ========================================================
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF172554), Color(0xFF1E3A8A)],
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.10),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.stars_rounded,
                                  color: Color(0xFFFBBF24),
                                  size: 27,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'SanCoins',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            '$_sanCoins',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Available SanCoins',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.65),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'SanCoin purchases will be available after payment integration.',
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Buy SanCoins'),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ========================================================
                    // WALLET OVERVIEW
                    // ========================================================
                    _sectionTitle('Wallet Overview'),

                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.55,
                      children: [
                        _statCard(
                          'SanCoins earned',
                          '$_earnedCoins',
                          Icons.trending_up_rounded,
                        ),
                        _statCard(
                          'SanCoins spent',
                          '0',
                          Icons.trending_down_rounded,
                        ),
                        _statCard(
                          'Documents purchased',
                          '0',
                          Icons.shopping_bag_outlined,
                        ),
                        _statCard('Documents sold', '0', Icons.sell_outlined),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // ========================================================
                    // SANCOIN PACKAGES
                    // ========================================================
                    _sectionTitle('SanCoin Packages'),

                    _packageCard(coins: 100, price: '₹10'),
                    _packageCard(coins: 500, price: '₹45', popular: true),
                    _packageCard(coins: 1000, price: '₹80'),

                    const SizedBox(height: 28),

                    // ========================================================
                    // TRANSACTION HISTORY
                    // ========================================================
                    _sectionTitle('Transaction History'),

                    _actionTile(
                      icon: Icons.receipt_long_rounded,
                      title: 'View All Transactions',
                      subtitle: 'See your complete SanCoin activity',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const SanCoinTransactionHistoryScreen(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 18),

                    // ========================================================
                    // PAYMENTS
                    // ========================================================
                    _sectionTitle('Payments'),

                    _actionTile(
                      icon: Icons.payment_rounded,
                      title: 'Payment History',
                      subtitle: 'View your payment records',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Payment history will be connected to Cashfree.',
                            ),
                          ),
                        );
                      },
                    ),

                    _actionTile(
                      icon: Icons.currency_exchange_rounded,
                      title: 'Refunds',
                      subtitle: 'View eligible refunds and refund status',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Refund management will be added with payment integration.',
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 18),

                    // ========================================================
                    // SELLER EARNINGS
                    // ========================================================
                    _sectionTitle('Seller Earnings'),

                    _actionTile(
                      icon: Icons.account_balance_wallet_rounded,
                      title: 'Earnings',
                      subtitle: 'View earnings from your resources',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Seller earnings will be connected to the final settlement system.',
                            ),
                          ),
                        );
                      },
                    ),

                    _actionTile(
                      icon: Icons.account_balance_rounded,
                      title: 'Payouts',
                      subtitle: 'Manage eligible seller payouts',
                      enabled: false,
                      onTap: () {},
                    ),

                    const SizedBox(height: 18),

                    // ========================================================
                    // FINAL WALLET OPTION — WATCH ADS
                    // ========================================================
                    _sectionTitle('Earn SanCoins'),

                    _actionTile(
                      icon: Icons.ondemand_video_rounded,
                      title: 'Watch Ads & Earn SanCoins',
                      subtitle: 'Watch a rewarded ad and earn SanCoins',
                      iconColor: const Color(0xFFF59E0B),
                      onTap: _watchAdAndEarn,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
