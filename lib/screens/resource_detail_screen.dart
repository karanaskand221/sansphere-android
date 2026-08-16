import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../global_state.dart';
import '../models/academic_resource.dart';
import '../services/sancoin_service.dart';
import '../services/resource_rating_service.dart';
import '../services/saved_resource_service.dart';
import 'chat_list_screen.dart';
import 'public_profile_screen.dart';

class ResourceDetailScreen extends StatefulWidget {
  final AcademicResource resource;
  final GlobalState globalState;

  const ResourceDetailScreen({
    super.key,
    required this.resource,
    required this.globalState,
  });

  @override
  State<ResourceDetailScreen> createState() => _ResourceDetailScreenState();
}

class _ResourceDetailScreenState extends State<ResourceDetailScreen> {
  final SanCoinService _sanCoinService = SanCoinService.instance;
  final ResourceRatingService _ratingService = ResourceRatingService.instance;
  final SavedResourceService _savedResourceService =
      SavedResourceService.instance;
  final TextEditingController _reviewController = TextEditingController();

  bool _loadingPurchaseState = true;
  bool _purchased = false;
  bool _saved = false;
  bool _savingResource = false;
  bool _processingPurchase = false;
  bool _opening = false;

  bool _loadingRating = true;
  bool _submittingRating = false;
  int _selectedRating = 0;
  bool _hasRated = false;

  Stream<QuerySnapshot<Map<String, dynamic>>>? _ratingsStream;

  @override
  void initState() {
    _loadSavedState();
    super.initState();

    if (_resourceId.isNotEmpty) {
      _ratingsStream = _ratingService.streamRatings(_resourceId);
    }

    _checkPurchase();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  String get _resourceId {
    final id = widget.resource.id.trim();
    if (id.isNotEmpty) return id;

    return widget.resource.customDocId.trim();
  }

  int get _price {
    final price = widget.resource.price;

    if (!price.isFinite) return -1;

    return price.round();
  }

  Future<void> _loadSavedState() async {
    try {
      final saved = await _savedResourceService.isSaved(_resourceId);

      if (!mounted) return;

      setState(() {
        _saved = saved;
      });
    } catch (_) {
      // Saving is optional UI state; do not block resource details.
    }
  }

  Future<void> _toggleSavedResource() async {
    if (_savingResource) return;

    setState(() {
      _savingResource = true;
    });

    try {
      if (_saved) {
        await _savedResourceService.removeSavedResource(_resourceId);

        if (!mounted) return;

        setState(() {
          _saved = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Removed from Saved Resources.')),
        );
      } else {
        await _savedResourceService.saveResource(_resourceId);

        if (!mounted) return;

        setState(() {
          _saved = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved to Saved Resources.')),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not update saved resource: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _savingResource = false;
        });
      }
    }
  }

  Future<void> _checkPurchase() async {
    if (_resourceId.isEmpty) {
      if (mounted) {
        setState(() {
          _loadingPurchaseState = false;
        });
      }
      return;
    }

    try {
      final purchased = await _sanCoinService.checkPurchase(_resourceId);

      if (!mounted) return;

      setState(() {
        _purchased = purchased;
        _loadingPurchaseState = false;
      });

      await _loadMyRating();
    } catch (e) {
      debugPrint('Purchase check failed: $e');

      if (!mounted) return;

      setState(() {
        _loadingPurchaseState = false;
      });
    }
  }

  Future<void> _loadMyRating() async {
    if (!_purchased || _resourceId.isEmpty) {
      if (mounted) {
        setState(() {
          _loadingRating = false;
        });
      }
      return;
    }

    try {
      final existing = await _ratingService.getMyRating(_resourceId);

      if (!mounted) return;

      setState(() {
        _hasRated = existing != null;
        _selectedRating = (existing?['rating'] as num?)?.toInt() ?? 0;
        _reviewController.text = (existing?['review'] as String?)?.trim() ?? '';
        _loadingRating = false;
      });
    } catch (e) {
      debugPrint('Rating load failed: $e');

      if (!mounted) return;

      setState(() {
        _loadingRating = false;
      });
    }
  }

  Future<void> _submitRating() async {
    if (_submittingRating) return;

    if (!_purchased) {
      _showError('Purchase this resource before rating it.');
      return;
    }

    if (_selectedRating < 1 || _selectedRating > 5) {
      _showError('Please select a rating from 1 to 5 stars.');
      return;
    }

    setState(() {
      _submittingRating = true;
    });

    try {
      await _ratingService.submitRating(
        resourceId: _resourceId,
        rating: _selectedRating,
        review: _reviewController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        _hasRated = true;
        _submittingRating = false;
      });

      _showSuccess(
        _hasRated
            ? 'Your rating has been saved successfully.'
            : 'Rating submitted successfully.',
      );
    } catch (e) {
      debugPrint('Rating submission failed: $e');

      if (!mounted) return;

      setState(() {
        _submittingRating = false;
      });

      _showError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Widget _buildPublicRatings() {
    final stream = _ratingsStream;

    if (stream == null) {
      return const Text(
        'No ratings yet.',
        style: TextStyle(color: Color(0xFF64748B)),
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          debugPrint('Ratings stream failed: ${snapshot.error}');

          return const Text(
            'Unable to load ratings right now.',
            style: TextStyle(color: Color(0xFF64748B)),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Text(
            'No ratings or reviews yet. Be the first purchaser to review this resource.',
            style: TextStyle(color: Color(0xFF64748B), height: 1.45),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...docs.map((doc) {
              final data = doc.data();

              final rating = (data['rating'] as num?)?.toInt() ?? 0;
              final userName =
                  (data['userName'] as String?)?.trim().isNotEmpty == true
                  ? (data['userName'] as String).trim()
                  : 'Anonymous';

              final review = (data['review'] as String?)?.trim() ?? '';

              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: const Color(0xFFEFF6FF),
                          child: Text(
                            userName.isNotEmpty
                                ? userName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Color(0xFF2563EB),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            userName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(5, (index) {
                            final star = index + 1;

                            return Icon(
                              star <= rating
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              size: 18,
                              color: const Color(0xFFF59E0B),
                            );
                          }),
                        ),
                      ],
                    ),
                    if (review.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        review,
                        style: const TextStyle(
                          color: Color(0xFF334155),
                          height: 1.45,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildRatingSection() {
    return _section(
      title: 'Rating & Reviews',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPublicRatings(),
          const SizedBox(height: 18),
          if (_loadingRating)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(),
              ),
            )
          else if (!_purchased)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lock_outline_rounded, color: Color(0xFF64748B)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Purchase this resource to submit your own rating and review.',
                      style: TextStyle(color: Color(0xFF475569), height: 1.45),
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _hasRated
                      ? 'Update your rating'
                      : 'How would you rate this resource?',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final star = index + 1;

                    return IconButton(
                      tooltip: '$star star${star == 1 ? '' : 's'}',
                      onPressed: _submittingRating
                          ? null
                          : () {
                              setState(() {
                                _selectedRating = star;
                              });
                            },
                      icon: Icon(
                        star <= _selectedRating
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        size: 38,
                        color: star <= _selectedRating
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFF94A3B8),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _reviewController,
                  enabled: !_submittingRating,
                  maxLines: 4,
                  maxLength: 500,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    hintText: 'Write an optional review...',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _submittingRating ? null : _submitRating,
                    icon: _submittingRating
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.star_rounded),
                    label: Text(
                      _submittingRating
                          ? 'Saving...'
                          : (_hasRated ? 'Update Rating' : 'Submit Rating'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _purchaseResource() async {
    if (_resourceId.isEmpty) {
      _showError('This resource has an invalid document ID.');
      return;
    }

    if (_price < 0) {
      _showError('This resource has an invalid price.');
      return;
    }

    if (_processingPurchase) return;

    if (_price == 0) {
      setState(() {
        _processingPurchase = true;
      });

      try {
        final result = await _sanCoinService.purchaseResource(_resourceId);

        final success = result['success'] == true;

        if (!success) {
          throw Exception('Free resource could not be unlocked.');
        }

        if (!mounted) return;

        setState(() {
          _purchased = true;
        });

        await _loadMyRating();
        _showSuccess('Free resource unlocked!');
      } catch (e) {
        debugPrint('Free resource unlock failed: $e');

        if (!mounted) return;

        _showError(_friendlyPurchaseError(e));
      } finally {
        if (mounted) {
          setState(() {
            _processingPurchase = false;
          });
        }
      }

      return;
    }

    final confirmed = await _showPurchaseConfirmation();

    if (!confirmed || !mounted) return;

    setState(() {
      _processingPurchase = true;
    });

    try {
      final result = await _sanCoinService.purchaseResource(_resourceId);

      final success = result['success'] == true;
      final alreadyPurchased = result['alreadyPurchased'] == true;

      if (!success) {
        throw Exception('Purchase was not completed.');
      }

      if (!mounted) return;

      setState(() {
        _purchased = true;
      });

      if (alreadyPurchased) {
        _showSuccess('You already own this resource.');
      } else {
        _showSuccess('Purchase successful! $_price SanCoins spent.');
      }
    } catch (e) {
      debugPrint('Purchase failed: $e');

      if (!mounted) return;

      _showError(_friendlyPurchaseError(e));
    } finally {
      if (mounted) {
        setState(() {
          _processingPurchase = false;
        });
      }
    }
  }

  Future<bool> _showPurchaseConfirmation() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.shopping_cart_rounded),
              SizedBox(width: 10),
              Expanded(child: Text('Purchase Resource')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.resource.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.monetization_on_rounded,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Cost: $_price SanCoins',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'This purchase is permanent. Once purchased, you can access the file again without paying again.',
                style: TextStyle(height: 1.4, color: Colors.black87),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              icon: const Icon(Icons.check_rounded),
              label: Text('Buy for $_price'),
            ),
          ],
        );
      },
    );

    return result == true;
  }

  Future<void> _openFile() async {
    if (_opening) return;

    if (_resourceId.isEmpty) {
      _showError('This resource has an invalid document ID.');
      return;
    }

    if (!_purchased) {
      _showError('Purchase this resource before downloading it.');
      return;
    }

    setState(() {
      _opening = true;
    });

    try {
      /*
       * IMPORTANT:
       *
       * Do NOT use resource.fileUrl here.
       *
       * The Storage rules intentionally deny direct reads.
       * The Cloud Function verifies permanent ownership and
       * returns a short-lived signed URL.
       */
      final signedUrl = await _sanCoinService.getPurchasedFileUrl(_resourceId);

      final uri = Uri.tryParse(signedUrl);

      if (uri == null || !uri.hasScheme) {
        throw Exception('Invalid secure download URL.');
      }

      bool launched;

      if (kIsWeb) {
        launched = await launchUrl(uri, webOnlyWindowName: '_blank');
      } else {
        launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      }

      if (!launched) {
        throw Exception('Could not open the purchased file.');
      }
    } catch (e) {
      debugPrint('Secure file open failed: $e');

      if (mounted) {
        _showError(_friendlyDownloadError(e));
      }
    } finally {
      if (mounted) {
        setState(() {
          _opening = false;
        });
      }
    }
  }

  String _friendlyPurchaseError(Object error) {
    final message = error.toString();

    if (message.contains('Insufficient SanCoins')) {
      return message.replaceFirst('Exception: ', '');
    }

    if (message.contains('permission-denied')) {
      return 'You are not authorized to make this purchase.';
    }

    if (message.contains('unauthenticated')) {
      return 'Please sign in again and try again.';
    }

    if (message.contains('User profile missing')) {
      return 'Your SanCoins wallet is not initialized yet.';
    }

    if (message.contains('already own')) {
      return 'You already own this document.';
    }

    if (message.contains('Invalid document price')) {
      return 'This resource has an invalid price.';
    }

    return 'Purchase failed. Please try again.';
  }

  String _friendlyDownloadError(Object error) {
    final message = error.toString();

    if (message.contains('Purchase required')) {
      return 'Purchase this resource before downloading it.';
    }

    if (message.contains('permission-denied')) {
      return 'You do not have access to this resource.';
    }

    if (message.contains('unauthenticated')) {
      return 'Please sign in again and try again.';
    }

    if (message.contains('storage path')) {
      return 'The file is not configured correctly on the server.';
    }

    return 'Could not open the purchased file. Please try again.';
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatSize(double mb) {
    if (mb <= 0) return 'Unknown size';

    if (mb < 1) {
      return '${(mb * 1024).toStringAsFixed(0)} KB';
    }

    return '${mb.toStringAsFixed(2)} MB';
  }

  IconData _fileIcon(String name) {
    final extension = name.split('.').last.toLowerCase();

    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'doc':
      case 'docx':
        return Icons.article_rounded;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow_rounded;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart_rounded;
      case 'zip':
        return Icons.folder_zip_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final resource = widget.resource;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Resource Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: _saved ? 'Remove from Saved' : 'Save Resource',
            onPressed: _savingResource ? null : _toggleSavedResource,
            icon: _savingResource
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    _saved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 78,
                    height: 78,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      _fileIcon(resource.fileName),
                      size: 42,
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    resource.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    resource.fileName.isEmpty
                        ? 'Academic Resource'
                        : resource.fileName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _infoChip(
                        Icons.monetization_on_rounded,
                        '$_price SanCoins',
                      ),
                      _infoChip(
                        Icons.storage_rounded,
                        _formatSize(resource.fileSizeMb),
                      ),
                      _infoChip(
                        Icons.download_rounded,
                        '${resource.downloadCount} downloads',
                      ),
                      _infoChip(Icons.school_rounded, resource.department),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            if (!_loadingPurchaseState) _buildOwnershipBanner(),

            const SizedBox(height: 16),

            _section(
              title: 'About this resource',
              child: Text(
                resource.description.isEmpty
                    ? 'No description provided.'
                    : resource.description,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.55,
                  color: Color(0xFF334155),
                ),
              ),
            ),

            const SizedBox(height: 16),

            _section(
              title: 'Resource Information',
              child: Column(
                children: [
                  _detailRow('Subject', resource.subject),
                  _detailRow('Category', resource.type),
                  _detailRow('Semester', 'Semester ${resource.semester}'),
                  _detailRow('Department', resource.department),
                  _detailRow('College', resource.college),
                  _buildUploaderProfileRow(),
                  _detailRow('Document ID', resource.customDocId),
                ],
              ),
            ),

            const SizedBox(height: 16),

            if (resource.tags.isNotEmpty)
              _section(
                title: 'Tags',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: resource.tags.map((tag) {
                    return Chip(
                      label: Text(tag),
                      backgroundColor: const Color(0xFFEFF6FF),
                    );
                  }).toList(),
                ),
              ),

            const SizedBox(height: 16),

            _buildRatingSection(),

            const SizedBox(height: 24),

            _buildActionButton(),

            const SizedBox(height: 12),

            _buildMessageSellerButton(),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildOwnershipBanner() {
    if (_purchased) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFA7F3D0)),
        ),
        child: const Row(
          children: [
            Icon(Icons.verified_rounded, color: Color(0xFF059669)),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'You own this resource permanently.',
                style: TextStyle(
                  color: Color(0xFF065F46),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_rounded, color: Color(0xFFEA580C)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Purchase for $_price SanCoins to unlock this file permanently.',
              style: const TextStyle(
                color: Color(0xFF9A3412),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    if (_loadingPurchaseState) {
      return SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: null,
          child: const SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_purchased) {
      return SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton.icon(
          onPressed: _opening ? null : _openFile,
          icon: _opening
              ? const SizedBox(
                  height: 21,
                  width: 21,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.download_rounded),
          label: Text(
            _opening ? 'Opening...' : 'Open / Download File',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _processingPurchase ? null : _purchaseResource,
        icon: _processingPurchase
            ? const SizedBox(
                height: 21,
                width: 21,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.shopping_cart_rounded),
        label: Text(
          _processingPurchase ? 'Purchasing...' : 'Buy for $_price SanCoins',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _section({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'Not specified' : value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: const Color(0xFF475569)),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildUploaderProfileRow() {
    final uploaderUid = widget.resource.uploaderId.trim().isNotEmpty
        ? widget.resource.uploaderId.trim()
        : widget.resource.authorUid.trim();

    final uploaderName = widget.resource.uploaderName.trim().isNotEmpty
        ? widget.resource.uploaderName.trim()
        : widget.resource.authorName.trim();

    final displayName = uploaderName.isNotEmpty ? uploaderName : 'Anonymous';

    if (uploaderUid.isEmpty) {
      return _detailRow('Uploaded by', displayName);
    }

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PublicProfileScreen(userId: uploaderUid),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 110,
              child: Text(
                'Uploaded by',
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: const Color(0xFFEFF6FF),
                    child: Text(
                      displayName[0].toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFF2563EB),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF2563EB),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: Color(0xFF94A3B8),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageSellerButton() {
    final sellerUid = widget.resource.uploaderId.trim().isNotEmpty
        ? widget.resource.uploaderId.trim()
        : widget.resource.authorUid.trim();

    final sellerName = widget.resource.uploaderName.trim().isNotEmpty
        ? widget.resource.uploaderName.trim()
        : widget.resource.authorName.trim();

    if (sellerUid.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          startChatWithUser(
            context,
            peerUid: sellerUid,
            peerName: sellerName.isNotEmpty ? sellerName : 'Seller',
            docTitle: widget.resource.title,
            docId: _resourceId,
          );
        },
        icon: const Icon(Icons.chat_bubble_outline_rounded),
        label: const Text('Message Seller'),
      ),
    );
  }
}
