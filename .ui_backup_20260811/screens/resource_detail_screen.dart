import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../global_state.dart';
import '../models/academic_resource.dart';
import '../services/sancoin_service.dart';

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

  bool _loadingPurchaseState = true;
  bool _purchased = false;
  bool _processingPurchase = false;
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    _checkPurchase();
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
    } catch (e) {
      debugPrint('Purchase check failed: $e');

      if (!mounted) return;

      setState(() {
        _loadingPurchaseState = false;
      });
    }
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
        final result =
            await _sanCoinService.purchaseResource(_resourceId);

        final success = result['success'] == true;

        if (!success) {
          throw Exception('Free resource could not be unlocked.');
        }

        if (!mounted) return;

        setState(() {
          _purchased = true;
        });

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
        launched = await launchUrl(
          uri,
          webOnlyWindowName: '_blank',
        );
      } else {
        launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
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
                  _detailRow('Uploaded by', resource.uploaderName),
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

            const SizedBox(height: 24),

            _buildActionButton(),

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
}
