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
  String? _academicCustomCategory;
  String? _academicSelectedDepartment;
  int? _academicSelectedSemester;
  String _academicSelectedPrice = 'all';

  String get searchQuery => _academicSearchQuery;

  ResourceCategory? get selectedCategory => _academicSelectedCategory;

  String? get customCategory => _academicCustomCategory;

  String? get selectedDepartment => _academicSelectedDepartment;

  int? get selectedSemester => _academicSelectedSemester;

  String get selectedPrice => _academicSelectedPrice;

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

      final selectedDepartment = _academicSelectedDepartment;
      final matchesDepartment =
          selectedDepartment == null ||
          resource.department.trim().toLowerCase() ==
              selectedDepartment.trim().toLowerCase();

      final selectedSemester = _academicSelectedSemester;
      final matchesSemester =
          selectedSemester == null ||
          resource.semester == selectedSemester;

      final matchesPrice = switch (_academicSelectedPrice) {
        'free' => resource.price <= 0,
        'paid' => resource.price > 0,
        _ => true,
      };

      return matchesSearch &&
          matchesCategory &&
          matchesDepartment &&
          matchesSemester &&
          matchesPrice;
    }).toList();
  }

  void setSearchQuery(String value) {
    _academicSearchQuery = value;
    notifyListeners();
  }

  void setCategoryFilter(ResourceCategory? value) {
    _academicSelectedCategory = value;
    _academicCustomCategory = null;
    notifyListeners();
  }

  void setCustomCategoryFilter(String? value) {
    final cleaned = value?.trim();

    _academicCustomCategory =
        cleaned == null || cleaned.isEmpty ? null : cleaned;

    _academicSelectedCategory = null;
    notifyListeners();
  }

  void resetCategoryFilter() {
    if (_academicSelectedCategory == null &&
        _academicCustomCategory == null) {
      return;
    }

    _academicSelectedCategory = null;
    _academicCustomCategory = null;
    notifyListeners();
  }

  bool _matchesCustomCategory(
    AcademicResource resource,
    String value,
  ) {
    final query = value.trim().toLowerCase();

    return resource.type.trim().toLowerCase() == query ||
        resource.category.displayName.trim().toLowerCase() == query ||
        resource.category.name.trim().toLowerCase() == query;
  }

  void setDepartmentFilter(String? value) {
    final cleaned = value?.trim();

    _academicSelectedDepartment =
        cleaned == null || cleaned.isEmpty ? null : cleaned;

    notifyListeners();
  }

  void resetDepartmentFilter() {
    if (_academicSelectedDepartment == null) return;

    _academicSelectedDepartment = null;
    notifyListeners();
  }

  void setSemesterFilter(int? value) {
    _academicSelectedSemester = value;
    notifyListeners();
  }

  void resetSemesterFilter() {
    if (_academicSelectedSemester == null) return;

    _academicSelectedSemester = null;
    notifyListeners();
  }

  void setPriceFilter(String value) {
    final normalized = value.trim().toLowerCase();

    if (normalized != 'all' &&
        normalized != 'free' &&
        normalized != 'paid') {
      return;
    }

    _academicSelectedPrice = normalized;
    notifyListeners();
  }

  void resetPriceFilter() {
    if (_academicSelectedPrice == 'all') return;

    _academicSelectedPrice = 'all';
    notifyListeners();
  }

  void resetFilters() {
    _academicSearchQuery = '';
    _academicSelectedCategory = null;
    _academicCustomCategory = null;
    _academicSelectedDepartment = null;
    _academicSelectedSemester = null;
    _academicSelectedPrice = 'all';
    notifyListeners();
  }
}
