import 'package:flutter/material.dart';

import '../services/social_profile_service.dart';

class PublicProfileResourcesScreen extends StatefulWidget {
  final String userId;
  final String resourceType;
  final String title;

  const PublicProfileResourcesScreen({
    super.key,
    required this.userId,
    required this.resourceType,
    required this.title,
  });

  @override
  State<PublicProfileResourcesScreen> createState() =>
      _PublicProfileResourcesScreenState();
}

class _PublicProfileResourcesScreenState
    extends State<PublicProfileResourcesScreen> {
  final SocialProfileService _socialProfileService =
      SocialProfileService.instance;

  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> _resources = [];

  @override
  void initState() {
    super.initState();
    _loadResources();
  }

  Future<void> _loadResources() async {
    try {
      final resources = await _socialProfileService.getVisibleProfileResources(
        targetUid: widget.userId,
        resourceType: widget.resourceType,
      );

      if (!mounted) return;

      setState(() {
        _resources = resources;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      debugPrint('Profile resources error: $e');

      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'Unable to load resources.';
      });
    }
  }

  String _value(Map<String, dynamic> data, String key) {
    return data[key]?.toString() ?? '';
  }

  String _priceLabel(Map<String, dynamic> data) {
    final value = data['price'];

    final price = value is num
        ? value.toInt()
        : int.tryParse(value?.toString() ?? '') ?? 0;

    return price <= 0 ? 'FREE' : '$price SanCoins';
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF475569),
        ),
      ),
    );
  }

  Widget _resourceCard(Map<String, dynamic> data) {
    final title = _value(data, 'title');
    final subject = _value(data, 'subject');
    final department = _value(data, 'department');
    final type = _value(data, 'type');
    final rating = _value(data, 'rating');
    final ratingCount = _value(data, 'ratingCount');

    return Container(
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  color: Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title.isEmpty ? 'Untitled Resource' : title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          if (subject.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(subject, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],

          const SizedBox(height: 8),

          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (type.isNotEmpty) _chip(type),
              if (department.isNotEmpty) _chip(department),
              _chip(_priceLabel(data)),
              if (rating.isNotEmpty && rating != '0')
                _chip('★ $rating ($ratingCount)'),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 44, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(_error!),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _loading = true;
                        _error = null;
                      });
                      _loadResources();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : _resources.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  widget.resourceType == 'uploaded'
                      ? 'No uploaded resources are visible.'
                      : 'No purchased resources are visible.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadResources,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                itemCount: _resources.length,
                itemBuilder: (context, index) {
                  return _resourceCard(_resources[index]);
                },
              ),
            ),
    );
  }
}
