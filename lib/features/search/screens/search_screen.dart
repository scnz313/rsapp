import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/core/constants/app_colors.dart';
import '/core/constants/app_styles.dart';
import '/features/property/data/models/property_model.dart';
import '/features/property/presentation/providers/property_provider.dart';
import '/features/property/presentation/widgets/property_card.dart';
import '/features/home/widgets/search_filter_bar.dart';

class SearchScreen extends StatefulWidget {
  final String? initialQuery;

  const SearchScreen({Key? key, this.initialQuery}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isGridView = false;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialQuery ?? '';
    if (widget.initialQuery != null) {
      _performSearch(widget.initialQuery!);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;
    
    final provider = Provider.of<PropertyProvider>(context, listen: false);
    await provider.searchProperties(query);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: SearchFilterBar(
          controller: _searchController,
          onSearchSubmitted: _performSearch,
          onFilterTap: () {}, // Will implement filter functionality
        ),
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
        ],
      ),
      body: Consumer<PropertyProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.searchResults.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No properties found',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return _isGridView
              ? _buildSearchResultsGrid(provider.searchResults)
              : _buildSearchResultsList(provider.searchResults);
        },
      ),
    );
  }

  Widget _buildSearchResultsList(List<PropertyModel> properties) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: properties.length,
      itemBuilder: (context, index) {
        final property = properties[index];
        return PropertyCard(
          property: property,
          onTap: () => _navigateToPropertyDetail(property.id),
        );
      },
    );
  }

  Widget _buildSearchResultsGrid(List<PropertyModel> properties) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: properties.length,
      itemBuilder: (context, index) {
        final property = properties[index];
        return PropertyCard(
          property: property,
          isGridItem: true,
          onTap: () => _navigateToPropertyDetail(property.id),
        );
      },
    );
  }

  void _navigateToPropertyDetail(String? id) {
    if (id == null) return;
    Navigator.pushNamed(
      context,
      '/property/detail',
      arguments: id,
    );
  }
}
