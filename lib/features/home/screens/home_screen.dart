import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';

import '/core/constants/app_colors.dart';
import '/features/property/data/models/property_model.dart';
import '/features/property/presentation/providers/property_provider.dart';
import '/features/property/presentation/widgets/property_card.dart';
import '/features/home/widgets/search_filter_bar.dart';
import '/features/home/widgets/property_list_header.dart';
import '/features/home/widgets/featured_properties_carousel.dart';
import '/features/home/widgets/quick_filter_chips.dart';
import '/core/navigation/route_names.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController; // Replace PersistentTabController with TabController
  bool _isMapView = false;
  bool _isGridView = false;
  String _selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();
  final MapController _mapController = MapController();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProperties();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadProperties() async {
    final propertyProvider = Provider.of<PropertyProvider>(context, listen: false);
    await propertyProvider.fetchFeaturedProperties();
    await propertyProvider.fetchRecentProperties();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                pinned: false,
                floating: true,
                snap: true,
                title: const Text('Real Estate App'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () => Navigator.pushNamed(context, RouteNames.notifications),
                  ),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(120),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: SearchFilterBar(
                          controller: _searchController,
                          onSearchSubmitted: _handleSearch,
                          onFilterTap: _showFilterBottomSheet,
                        ),
                      ),
                      QuickFilterChips(
                        selectedFilter: _selectedFilter,
                        onFilterSelected: (filter) {
                          setState(() {
                            _selectedFilter = filter;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: _buildMainContent(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _toggleViewMode(),
        child: Icon(_isMapView ? Icons.list : Icons.map),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildMainContent() {
    return _isMapView ? _buildMapView() : _buildListView();
  }

  Widget _buildListView() {
    return Consumer<PropertyProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: _loadProperties,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Featured Properties Carousel
                FeaturedPropertiesCarousel(
                  properties: provider.featuredProperties,
                  onPropertyTap: (property) => _navigateToPropertyDetail(property.id),
                ),

                // Property List Header with view toggle
                PropertyListHeader(
                  title: 'Recent Properties',
                  isGridView: _isGridView,
                  onViewToggle: () {
                    setState(() {
                      _isGridView = !_isGridView;
                    });
                  },
                ),

                // Property Grid/List
                _isGridView
                    ? _buildPropertyGrid(provider.recentProperties)
                    : _buildPropertyList(provider.recentProperties),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPropertyList(List<PropertyModel> properties) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: properties.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final property = properties[index];
        return PropertyCard(
          property: property,
          onTap: () => _navigateToPropertyDetail(property.id),
        );
      },
    );
  }

  Widget _buildPropertyGrid(List<PropertyModel> properties) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
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

  Widget _buildMapView() {
    return Consumer<PropertyProvider>(
      builder: (context, provider, _) {
        final properties = provider.recentProperties;
        final markers = _createMarkers(properties);

        return Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(34.0522, -118.2437), // Los Angeles
                initialZoom: 10.0,
                interactionOptions: InteractionOptions( // Remove 'const' here
                  flags: InteractiveFlag.all,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                ),
                MarkerClusterLayerWidget(
                  options: MarkerClusterLayerOptions(
                    maxClusterRadius: 120,
                    size: const Size(40, 40),
                    markers: markers,
                    builder: (context, markers) {
                      return Container(
                        decoration: BoxDecoration(
                          color: AppColors.lightColorScheme.primary.withValues(
                            alpha: (0.8 * 255).toDouble(), // Use withValues instead of withOpacity
                            red: AppColors.lightColorScheme.primary.r.toDouble(),
                            green: AppColors.lightColorScheme.primary.g.toDouble(),
                            blue: AppColors.lightColorScheme.primary.b.toDouble(),
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            markers.length.toString(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: SearchFilterBar(
                controller: _searchController,
                onSearchSubmitted: _handleSearch,
                onFilterTap: _showFilterBottomSheet,
              ),
            ),
          ],
        );
      },
    );
  }
  
  List<Marker> _createMarkers(List<PropertyModel> properties) {
    return properties.map((property) {
      // Use default location if property doesn't have coordinates
      final LatLng position = property.latitude != null && property.longitude != null
          ? LatLng(property.latitude!, property.longitude!)
          : const LatLng(34.0522, -118.2437); // Default to LA
      
      return Marker(
        width: 40.0,
        height: 40.0,
        point: position,
        child: GestureDetector(
          onTap: () => _showPropertyBottomSheet(property),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.lightColorScheme.primary,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Center(
              child: Text(
                '\$${(property.price / 1000).round()}k',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  void _showPropertyBottomSheet(PropertyModel property) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 16),
                PropertyCard(
                  property: property,
                  onTap: () => _navigateToPropertyDetail(property.id),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: () => _navigateToPropertyDetail(property.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.lightColorScheme.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text('View Details'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 26, // 0.1 * 255 = approximately 26
              red: Colors.black.r.toDouble(),
              green: Colors.black.g.toDouble(),
              blue: Colors.black.b.toDouble(),
            ),
            blurRadius: 10,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavBarItem(Icons.home_outlined, 'Home', isSelected: true),
              _buildNavBarItem(Icons.search_outlined, 'Search'),
              _buildNavBarItem(Icons.add_circle_outline, 'Post'),
              _buildNavBarItem(Icons.favorite_border_outlined, 'Favorites'),
              _buildNavBarItem(Icons.person_outline, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavBarItem(IconData icon, String label, {bool isSelected = false}) {
    return InkWell(
      onTap: () {
        // Handle navigation based on label
        switch (label) {
          case 'Search':
            Navigator.pushNamed(context, RouteNames.search);
            break;
          case 'Post':
            Navigator.pushNamed(context, RouteNames.propertyCreate);
            break;
          case 'Favorites':
            Navigator.pushNamed(context, RouteNames.favorites);
            break;
          case 'Profile':
            Navigator.pushNamed(context, RouteNames.profile);
            break;
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected 
                ? AppColors.lightColorScheme.primary
                : Colors.grey,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected 
                  ? AppColors.lightColorScheme.primary
                  : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  void _toggleViewMode() {
    setState(() {
      _isMapView = !_isMapView;
    });
  }

  void _showFilterBottomSheet() {
    // Implement filter dialog/bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, controller) {
          return const FilterBottomSheet();
        },
      ),
    );
  }

  void _handleSearch(String query) {
    // Handle search functionality
    if (query.isEmpty) return;
    
    final provider = Provider.of<PropertyProvider>(context, listen: false);
    provider.searchProperties(query);
    
    // Navigate to search results
    Navigator.pushNamed(context, RouteNames.search, arguments: query);
  }

  void _navigateToPropertyDetail(String? id) {
    if (id == null) return;
    Navigator.pushNamed(
      context,
      RouteNames.propertyDetail,
      arguments: id,
    );
  }
}

// Filter Bottom Sheet
class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({Key? key}) : super(key: key);

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  RangeValues _priceRange = const RangeValues(100000, 1000000);
  int _bedrooms = 0;
  int _bathrooms = 0;
  String _propertyType = 'Any';
  bool _hasParking = false;
  bool _hasPool = false;
  bool _hasPets = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Filter Properties',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Price Range
          const Text(
            'Price Range',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          RangeSlider(
            values: _priceRange,
            min: 0,
            max: 2000000,
            divisions: 20,
            labels: RangeLabels(
              '\$${_priceRange.start.round()}',
              '\$${_priceRange.end.round()}',
            ),
            onChanged: (RangeValues values) {
              setState(() {
                _priceRange = values;
              });
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('\$${_priceRange.start.round()}'),
              Text('\$${_priceRange.end.round()}'),
            ],
          ),
          const SizedBox(height: 24),
          
          // Bedrooms & Bathrooms
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bedrooms',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(5, (index) {
                        return _buildSelectionChip(
                          index.toString(),
                          _bedrooms == index,
                          () {
                            setState(() {
                              _bedrooms = index;
                            });
                          },
                        );
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bathrooms',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(5, (index) {
                        return _buildSelectionChip(
                          index.toString(),
                          _bathrooms == index,
                          () {
                            setState(() {
                              _bathrooms = index;
                            });
                          },
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Property Type
          const Text(
            'Property Type',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              'Any',
              'House',
              'Apartment',
              'Condo',
              'Townhouse',
              'Land',
              'Commercial'
            ].map((type) {
              return _buildSelectionChip(
                type,
                _propertyType == type,
                () {
                  setState(() {
                    _propertyType = type;
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          
          // Amenities
          const Text(
            'Amenities',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildCheckboxItem('Parking', _hasParking, (value) {
            setState(() {
              _hasParking = value ?? false;
            });
          }),
          _buildCheckboxItem('Swimming Pool', _hasPool, (value) {
            setState(() {
              _hasPool = value ?? false;
            });
          }),
          _buildCheckboxItem('Pet Friendly', _hasPets, (value) {
            setState(() {
              _hasPets = value ?? false;
            });
          }),
          const SizedBox(height: 24),
          
          // Apply Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                final filters = {
                  'minPrice': _priceRange.start,
                  'maxPrice': _priceRange.end,
                  'bedrooms': _bedrooms > 0 ? _bedrooms : null,
                  'bathrooms': _bathrooms > 0 ? _bathrooms : null,
                  'propertyType': _propertyType != 'Any' ? _propertyType : null,
                  'hasParking': _hasParking ? true : null,
                  'hasPool': _hasPool ? true : null,
                  'hasPets': _hasPets ? true : null,
                };
                Navigator.pop(context, filters);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.lightColorScheme.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Apply Filters'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSelectionChip(String label, bool isSelected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: Colors.grey[200],
      selectedColor: AppColors.lightColorScheme.primary.withValues(
        alpha: 51,  // 0.2 * 255
        red: AppColors.lightColorScheme.primary.r.toDouble(),  // Use .r instead of .red
        green: AppColors.lightColorScheme.primary.g.toDouble(), // Use .g instead of .green
        blue: AppColors.lightColorScheme.primary.b.toDouble(), // Use .b instead of .blue
      ),
      labelStyle: TextStyle(
        color: isSelected 
            ? AppColors.lightColorScheme.primary
            : Colors.black,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildCheckboxItem(String label, bool value, ValueChanged<bool?> onChanged) {
    return CheckboxListTile(
      title: Text(label),
      value: value,
      onChanged: onChanged,
      controlAffinity: ListTileControlAffinity.leading,
      activeColor: AppColors.lightColorScheme.primary,
      contentPadding: EdgeInsets.zero,
    );
  }
}
