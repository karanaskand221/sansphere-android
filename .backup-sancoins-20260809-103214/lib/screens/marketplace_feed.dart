import 'package:flutter/material.dart';
import '../global_state.dart';
import '../models/academic_resource.dart';
import 'resource_detail_screen.dart';
import 'upload_resource_screen.dart';

class MarketplaceFeedScreen extends StatefulWidget {
  final GlobalState globalState;

  const MarketplaceFeedScreen({Key? key, required this.globalState})
    : super(key: key);

  @override
  State<MarketplaceFeedScreen> createState() => _MarketplaceFeedScreenState();
}

class _MarketplaceFeedScreenState extends State<MarketplaceFeedScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.globalState.searchQuery;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.globalState,
      builder: (context, _) {
        final resources = widget.globalState.filteredResources;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Academic Resource Hub'),
            elevation: 2,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Reset Filters',
                onPressed: () {
                  _searchController.clear();
                  widget.globalState.resetFilters();
                },
              ),
            ],
          ),
          body: Column(
            children: [
              // Search & Filter Header Section
              Container(
                padding: const EdgeInsets.all(12.0),
                color: Theme.of(context).primaryColor.withOpacity(0.05),
                child: Column(
                  children: [
                    // Search Bar
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search notes, subjects, tags...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  widget.globalState.setSearchQuery('');
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (val) {
                        widget.globalState.setSearchQuery(val);
                      },
                    ),
                    const SizedBox(height: 10),

                    // Category Chips Filter
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          FilterChip(
                            label: const Text('All Categories'),
                            selected:
                                widget.globalState.selectedCategory == null,
                            onSelected: (_) {
                              widget.globalState.setCategoryFilter(null);
                            },
                          ),
                          const SizedBox(width: 8),
                          ...ResourceCategory.values.map((cat) {
                            final isSelected =
                                widget.globalState.selectedCategory == cat;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: FilterChip(
                                label: Text(_formatCategoryName(cat)),
                                selected: isSelected,
                                onSelected: (selected) {
                                  widget.globalState.setCategoryFilter(
                                    selected ? cat : null,
                                  );
                                },
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Results Counter
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Found ${resources.length} resource(s)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Main Resource List
              Expanded(
                child: resources.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.folder_off_outlined,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'No matching resources found.',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                _searchController.clear();
                                widget.globalState.resetFilters();
                              },
                              child: const Text('Clear Filters'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: resources.length,
                        padding: const EdgeInsets.all(12),
                        itemBuilder: (context, index) {
                          final resource = resources[index];
                          return ResourceCard(
                            resource: resource,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ResourceDetailScreen(
                                    resource: resource,
                                    globalState: widget.globalState,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      UploadResourceScreen(globalState: widget.globalState),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Upload Resource'),
          ),
        );
      },
    );
  }

  String _formatCategoryName(ResourceCategory cat) {
    switch (cat) {
      case ResourceCategory.questionBank:
        return 'Question Bank';
      case ResourceCategory.pyq:
        return 'PYQ';
      case ResourceCategory.lectureNotes:
        return 'Lecture Notes';
      case ResourceCategory.textbook:
        return 'Textbook';
      case ResourceCategory.questionPaper:
        return 'Question Paper';
      case ResourceCategory.testPaper:
        return 'Test Paper';
      case ResourceCategory.labManual:
        return 'Lab Manual';
      case ResourceCategory.assignment:
        return 'Assignment';
      case ResourceCategory.other:
        return 'Other';
    }
  }
}

/// Card component to display individual academic resources
class ResourceCard extends StatelessWidget {
  final AcademicResource resource;
  final VoidCallback onTap;

  const ResourceCard({Key? key, required this.resource, required this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getCategoryIcon(resource.category),
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          resource.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${resource.subject} • Sem ${resource.semester}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                resource.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[800], fontSize: 13),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        '${resource.rating}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.download, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${resource.downloadCount}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${resource.fileSizeMb} MB',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(ResourceCategory cat) {
    switch (cat) {
      case ResourceCategory.questionBank:
        return Icons.quiz;
      case ResourceCategory.pyq:
        return Icons.description;
      case ResourceCategory.lectureNotes:
        return Icons.menu_book;
      case ResourceCategory.textbook:
        return Icons.book;
      case ResourceCategory.questionPaper:
        return Icons.quiz;
      case ResourceCategory.testPaper:
        return Icons.assignment;
      case ResourceCategory.labManual:
        return Icons.science;
      case ResourceCategory.assignment:
        return Icons.assignment;
      case ResourceCategory.other:
        return Icons.insert_drive_file;
    }
  }
}
