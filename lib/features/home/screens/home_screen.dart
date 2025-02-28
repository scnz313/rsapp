import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  
  Future<void> _loadProperties() async {
    final provider = Provider.of<PropertyProvider>(context, listen: false);
    await provider.fetchProperties();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProperties();
    
    // Apply status bar color as soon as widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setStatusBarColor();
    });
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    
    // Reset status bar color when leaving screen
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    super.dispose();
  }
  
  // Method to set status bar color
  void _setStatusBarColor() {
    final Color primaryColor = AppColors.lightColorScheme.primary;
    
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: primaryColor, // Set to exact same green color as header
      systemNavigationBarColor: primaryColor, // Also set bottom system nav color
      statusBarIconBrightness: Brightness.light, 
      systemNavigationBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark, // For iOS
    ));
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Refined header with better spacing and visual appeal
          Material(
            elevation: 2, // Slight elevation for better visual hierarchy
            color: AppColors.lightColorScheme.primary,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Status bar space
                SizedBox(height: MediaQuery.of(context).padding.top),
                
                // Search bar with improved spacing and size
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: SizedBox(
                    height: 46, // Increased from 40 for better touch target
                    child: SearchFilterBar(
                      controller: _searchController,
                      onSearchSubmitted: _handleSearch,
                      onFilterTap: _showFilterBottomSheet,
                    ),
                  ),
                ),
                
                // Filter chips with improved layout
                if (!_isMapView)
                  Container(
                    height: 46, // Increased height for better visibility
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _buildFilterChip('All', _selectedFilter == 'All'),
                        _buildFilterChip('For Sale', _selectedFilter == 'For Sale'),
                        _buildFilterChip('For Rent', _selectedFilter == 'For Rent'),
                        _buildFilterChip('Furnished', _selectedFilter == 'Furnished'),
                        _buildFilterChip('Newest', _selectedFilter == 'Newest'),
                        _buildFilterChip('Price ↓', _selectedFilter == 'Price ↓'),
                      ],
                    ),
                  ),
                
                // Curved bottom edge with shadow effect
                Container(
                  height: 20, // Increased height for more pronounced curve
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        offset: const Offset(0, -2),
                        blurRadius: 4,
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Main content
          Expanded(child: _buildMainContent()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _toggleViewMode(),
        icon: Icon(_isMapView ? Icons.view_list_rounded : Icons.map_rounded),
        label: Text(_isMapView ? 'List' : 'Map'),
        backgroundColor: AppColors.lightColorScheme.primary,
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  // Updated filter chip with better styling
  Widget _buildFilterChip(String label, bool isSelected) {
    return GestureDetector(
      onTap: () => _updateFilter(label),
      child: Container(
        margin: const EdgeInsets.only(right: 10, top: 4, bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.lightColorScheme.primary : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
            letterSpacing: 0.2, // Improved typography
          ),
        ),
      ),
    );
  }
  
  // Helper method to update filter safely
  void _updateFilter(String filter) {
    if (_selectedFilter != filter) {
      Future.microtask(() {
        setState(() {
          _selectedFilter = filter;
        });
      });
    }
  }

  Widget _buildSearchBar() {
    return Container(
      height: 40, // Reduced from 44
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(
            Icons.search_rounded,
            color: AppColors.lightColorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search properties...',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
                hintStyle: TextStyle(
                  color: Colors.grey,
                  fontSize: 15,
                ),
              ),
              style: const TextStyle(fontSize: 15),
              textInputAction: TextInputAction.search,
              onSubmitted: _handleSearch,
            ),
          ),
          Container(
            height: 24,
            width: 1,
            color: Colors.grey[300],
            margin: const EdgeInsets.symmetric(horizontal: 8),
          ),
          IconButton(
            icon: Icon(
              Icons.tune_rounded,
              color: AppColors.lightColorScheme.primary,
              size: 20,
            ),
            onPressed: _showFilterBottomSheet,
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          _buildFilterChip('All', _selectedFilter == 'All'),
          _buildFilterChip('For Sale', _selectedFilter == 'For Sale'),
          _buildFilterChip('For Rent', _selectedFilter == 'For Rent'),
          _buildFilterChip('Furnished', _selectedFilter == 'Furnished'),
          _buildFilterChip('Newest', _selectedFilter == 'Newest'),
          _buildFilterChip('Price ↓', _selectedFilter == 'Price ↓'),
        ],
      ),
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

        return FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: LatLng(34.0837, 74.7973), // KASHMIR 
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
                        red: AppColors.lightColorScheme.primary.r.toDouble(), // Use .r instead of .red
                        green: AppColors.lightColorScheme.primary.g.toDouble(), // Use .g instead of .green
                        blue: AppColors.lightColorScheme.primary.b.toDouble(), // Use .b instead of .blue
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
        );
      },
    );
  }
  
  List<Marker> _createMarkers(List<PropertyModel> properties) {
    return properties.map((property) {
     // Use default location if property doesn't have coordinates
final LatLng position = property.latitude != null && property.longitude != null
    ? LatLng(property.latitude!, property.longitude!)
    : const LatLng(34.0837, 74.7973); // Default to Srinagar, Kashmir
      return Marker(
        width: 50.0,
        height: 50.0,
        point: position,
        child: GestureDetector(
          onTap: () => _showPropertyBottomSheet(property),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.lightColorScheme.primary,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '\$${(property.price / 1000).round()}k',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
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
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavBarItem(Icons.home_rounded, 'Home', isSelected: true),
              _buildNavBarItem(Icons.search_rounded, 'Search'),
              _buildNavBarItem(Icons.add_circle_rounded, 'Post'),
              _buildNavBarItem(Icons.favorite_rounded, 'Favorites'),
              _buildNavBarItem(Icons.person_rounded, 'Profile'),
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
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.lightColorScheme.primary.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(14.0),
            ),
            child: Icon(
              icon,
              color: isSelected 
                  ? AppColors.lightColorScheme.primary
                  : Colors.grey,
              size: isSelected ? 28 : 24,
            ),
          ),
          const SizedBox(height: 4),
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
