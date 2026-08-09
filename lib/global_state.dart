import 'package:flutter/foundation.dart';
import 'models/academic_resource.dart';

class GlobalState extends ChangeNotifier {
  static Map<String, double> creatorEarnings = {};
  static double currentUserWallet = 0.0;
  static double platformProcessingPool = 0.0;

  final List<AcademicResource> _resources = [];

  List<AcademicResource> get resources => List.unmodifiable(_resources);

  void addResource(dynamic resource) {
    if (resource is AcademicResource) {
      _resources.add(resource);
    } else if (resource is Map<String, dynamic>) {
      _resources.add(AcademicResource.fromMap(resource));
    }
    notifyListeners();
  }

  bool removeResourceById(String id) {
    final initialLength = _resources.length;
    _resources.removeWhere((item) => item.id == id || item.customDocId == id);
    final removed = initialLength != _resources.length;
    if (removed) {
      notifyListeners();
    }
    return removed;
  }

  // ==========================================================
  // Academic Vault / Marketplace filter compatibility API
  // ==========================================================

  String _academicSearchQuery = '';

  ResourceCategory? _academicSelectedCategory;

  String get searchQuery => _academicSearchQuery;

  ResourceCategory? get selectedCategory => _academicSelectedCategory;

  List<AcademicResource> get filteredResources {
    final query = _academicSearchQuery.trim().toLowerCase();

    return _resources.where((resource) {
      final matchesSearch =
          query.isEmpty ||
          resource.title.toLowerCase().contains(query) ||
          resource.subject.toLowerCase().contains(query) ||
          resource.description.toLowerCase().contains(query) ||
          resource.uploaderName.toLowerCase().contains(query) ||
          resource.tags.any((tag) => tag.toLowerCase().contains(query));

      final matchesCategory =
          _academicSelectedCategory == null ||
          resource.category == _academicSelectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();
  }

  void setSearchQuery(String value) {
    _academicSearchQuery = value;
    notifyListeners();
  }

  void setCategoryFilter(ResourceCategory? value) {
    _academicSelectedCategory = value;
    notifyListeners();
  }

  void resetFilters() {
    _academicSearchQuery = '';
    _academicSelectedCategory = null;
    notifyListeners();
  }
}
