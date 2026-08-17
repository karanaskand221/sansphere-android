import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileReviewsScreen extends StatefulWidget {
  final String profileUid;
  final String profileName;
  final bool canReview;

  const ProfileReviewsScreen({
    super.key,
    required this.profileUid,
    required this.profileName,
    this.canReview = true,
  });

  @override
  State<ProfileReviewsScreen> createState() => _ProfileReviewsScreenState();
}

class _ProfileReviewsScreenState extends State<ProfileReviewsScreen> {
  final _functions = FirebaseFunctions.instanceFor(region: 'us-central1');

  bool _loading = true;
  bool _saving = false;

  List<Map<String, dynamic>> _reviews = [];
  Map<String, dynamic>? _myReview;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    try {
      final result = await _functions.httpsCallable('getProfileReviews').call({
        'profileUid': widget.profileUid,
      });

      final data = result.data;

      final reviews = <Map<String, dynamic>>[];

      if (data is Map && data['reviews'] is List) {
        for (final item in data['reviews']) {
          if (item is Map) {
            reviews.add(Map<String, dynamic>.from(item));
          }
        }
      }

      Map<String, dynamic>? myReview;

      try {
        final mine = await _functions.httpsCallable('getMyProfileReview').call({
          'profileUid': widget.profileUid,
        });

        final mineData = mine.data;

        if (mineData is Map && mineData['review'] is Map) {
          myReview = Map<String, dynamic>.from(mineData['review']);
        }
      } catch (_) {}

      if (!mounted) return;

      setState(() {
        _reviews = reviews;
        _myReview = myReview;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to load reviews: $e')));
    }
  }

  Future<void> _writeReview() async {
    if (!widget.canReview) return;

    int rating = (_myReview?['rating'] ?? 5) is num
        ? (_myReview?['rating'] ?? 5).toInt()
        : 5;

    final controller = TextEditingController(
      text: (_myReview?['review'] ?? '').toString(),
    );

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      _myReview == null
                          ? 'Review ${widget.profileName}'
                          : 'Edit your review',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Your rating',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(5, (index) {
                        final value = index + 1;

                        return IconButton(
                          onPressed: () {
                            setSheetState(() {
                              rating = value;
                            });
                          },
                          icon: Icon(
                            value <= rating
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: const Color(0xFFF59E0B),
                            size: 34,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: controller,
                      maxLines: 4,
                      maxLength: 500,
                      decoration: InputDecoration(
                        hintText: 'Write your review...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(sheetContext, {
                            'rating': rating,
                            'review': controller.text.trim(),
                          });
                        },
                        child: Text(
                          _myReview == null ? 'Submit Review' : 'Update Review',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    controller.dispose();

    if (result == null) return;

    await _submitReview(
      rating: result['rating'] as int,
      review: result['review'] as String,
    );
  }

  Future<void> _submitReview({
    required int rating,
    required String review,
  }) async {
    if (_saving) return;

    setState(() {
      _saving = true;
    });

    try {
      await _functions.httpsCallable('submitProfileReview').call({
        'profileUid': widget.profileUid,
        'rating': rating,
        'review': review,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Review saved successfully.'),
          backgroundColor: Colors.green,
        ),
      );

      await _loadReviews();
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Unable to save review.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to save review: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Widget _stars(dynamic value) {
    final rating = value is num ? value.toInt() : 0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (index) => Icon(
          index < rating ? Icons.star_rounded : Icons.star_border_rounded,
          size: 18,
          color: const Color(0xFFF59E0B),
        ),
      ),
    );
  }

  Widget _reviewCard(Map<String, dynamic> review) {
    final name = (review['reviewerName'] ?? 'Sansphere User').toString();

    final username = (review['reviewerUsername'] ?? '').toString();

    final text = (review['review'] ?? '').toString();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFEFF6FF),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    if (username.isNotEmpty)
                      Text(
                        '@$username',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              _stars(review['rating']),
            ],
          ),
          if (text.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(text, style: const TextStyle(fontSize: 14, height: 1.4)),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOwnProfile =
        FirebaseAuth.instance.currentUser?.uid == widget.profileUid;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Reviews'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadReviews,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.rate_review_rounded,
                          color: Color(0xFF2563EB),
                          size: 30,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_reviews.length} Reviews',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Reviews for ${widget.profileName}',
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isOwnProfile && widget.canReview) ...[
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _saving ? null : _writeReview,
                        icon: const Icon(Icons.star_rounded),
                        label: Text(
                          _myReview == null
                              ? 'Write a Review'
                              : 'Edit Your Review',
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  if (_reviews.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 50),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.rate_review_outlined,
                              size: 48,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'No reviews yet.',
                              style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._reviews.map(_reviewCard),
                ],
              ),
            ),
    );
  }
}
