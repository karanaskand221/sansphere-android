import 'dart:typed_data';

import 'package:flag_secure/flag_secure.dart';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

class ProtectedDocumentViewerScreen extends StatefulWidget {
  const ProtectedDocumentViewerScreen({
    super.key,
    required this.documentBytes,
    required this.title,
    this.previewOnly = false,
  });

  final Uint8List documentBytes;
  final String title;
  final bool previewOnly;

  @override
  State<ProtectedDocumentViewerScreen> createState() =>
      _ProtectedDocumentViewerScreenState();
}

class _ProtectedDocumentViewerScreenState
    extends State<ProtectedDocumentViewerScreen> {
  bool _securityEnabled = false;
  bool _loading = true;
  String? _error;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _enableProtection();

    if (widget.previewOnly) {
      Future<void>.delayed(const Duration(seconds: 10), _autoClosePreview);
    }
  }

  Future<void> _autoClosePreview() async {
    if (!mounted || _closing) return;

    _closing = true;

    await _disableProtection();

    if (!mounted) return;

    Navigator.of(context).pop();
  }

  Future<void> _enableProtection() async {
    try {
      await FlagSecure.set();

      if (!mounted) return;

      setState(() {
        _securityEnabled = true;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Could not enable screen protection: $e');

      if (!mounted) return;

      // The document can still be displayed, but we explicitly surface
      // that platform protection could not be enabled.
      setState(() {
        _loading = false;
        _error = 'Screen protection could not be enabled on this device.';
      });
    }
  }

  Future<void> _disableProtection() async {
    if (!_securityEnabled) return;

    try {
      await FlagSecure.unset();
    } catch (e) {
      debugPrint('Could not disable screen protection: $e');
    } finally {
      _securityEnabled = false;
    }
  }

  @override
  void dispose() {
    // We cannot await inside dispose. Fire the cleanup asynchronously.
    if (_securityEnabled) {
      FlagSecure.unset().catchError((Object error) {
        debugPrint('Protected viewer cleanup failed: $error');
      });
      _securityEnabled = false;
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || _closing) return;

        _closing = true;
        final navigator = Navigator.of(context);
        await _disableProtection();

        if (!mounted) return;
        navigator.pop();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
          titleSpacing: 0,
          title: Text(
            widget.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          leading: IconButton(
            tooltip: 'Close',
            icon: const Icon(Icons.close_rounded),
            onPressed: () async {
              if (_closing) return;

              _closing = true;
              final navigator = Navigator.of(context);
              await _disableProtection();

              if (!mounted) return;
              navigator.pop();
            },
          ),
          actions: [
            if (_securityEnabled)
              const Padding(
                padding: EdgeInsets.only(right: 16),
                child: Icon(
                  Icons.shield_rounded,
                  size: 20,
                  color: Colors.white70,
                ),
              ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        PdfViewer.data(
          widget.documentBytes,
          sourceName: 'sansphere_${widget.title}',
          params: const PdfViewerParams(backgroundColor: Colors.black),
        ),
        if (_error != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
