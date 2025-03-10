import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/property_model.dart';
import '../../../../core/utils/debug_logger.dart';
import '../../../../core/utils/dev_utils.dart';

/// Service class for handling property-related operations
class PropertyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetch a property by its ID
  Future<PropertyModel> getPropertyById(String id) async {
    try {
      // Check if we're in development mode and using a dev property ID
      if (DevUtils.isDevMode &&
          (id.startsWith('dev-') || id.contains('example'))) {
        DebugLogger.info('🛠️ DEV: Using mock data for property ID: $id');
        return _getMockProperty(id);
      }

      // Otherwise fetch from Firestore
      final docSnapshot =
          await _firestore.collection('properties').doc(id).get();

      if (!docSnapshot.exists) {
        throw Exception('Property not found');
      }

      return PropertyModel.fromFirestore(docSnapshot);
    } catch (e) {
      DebugLogger.error('Failed to get property by ID: $id', e);
      throw Exception('Error loading property: ${e.toString()}');
    }
  }

  /// Fetch all properties
  Future<List<PropertyModel>> getAllProperties({
    String? filterType,
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      // Check if we're in development mode
      if (DevUtils.isDevMode) {
        DebugLogger.info('🛠️ DEV: Using mock data for property listing');
        return _getMockProperties();
      }

      // Start building the query
      Query query = _firestore.collection('properties');

      // Apply filters if needed
      if (filterType != null) {
        query = query.where('listingType', isEqualTo: filterType);
      }

      // Order by creation date (newest first)
      query = query.orderBy('createdAt', descending: true);

      // Apply pagination
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      // Apply limit
      query = query.limit(limit);

      // Execute the query
      final querySnapshot = await query.get();

      // Convert to list of PropertyModel objects
      return querySnapshot.docs
          .map((doc) => PropertyModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      DebugLogger.error('Failed to get properties', e);
      throw Exception('Error loading properties: ${e.toString()}');
    }
  }

  /// Get featured properties
  Future<List<PropertyModel>> getFeaturedProperties({int limit = 10}) async {
    try {
      // Check if we're in development mode
      if (DevUtils.isDevMode) {
        DebugLogger.info('🛠️ DEV: Using mock data for featured properties');
        return _getMockProperties().where((p) => p.featured).toList();
      }

      // Query for featured properties
      final querySnapshot = await _firestore
          .collection('properties')
          .where('featured', isEqualTo: true)
          .where('isApproved', isEqualTo: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => PropertyModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      DebugLogger.error('Failed to get featured properties', e);
      throw Exception('Error loading featured properties: ${e.toString()}');
    }
  }

  /// Get properties for a specific owner
  Future<List<PropertyModel>> getPropertiesByOwner(String ownerId) async {
    try {
      // Check if we're in development mode
      if (DevUtils.isDevMode &&
          (ownerId == 'dev-user-123' || ownerId.contains('example'))) {
        DebugLogger.info('🛠️ DEV: Using mock data for owner properties');
        return _getMockProperties().where((p) => p.ownerId == ownerId).toList();
      }

      // Query for properties by owner
      final querySnapshot = await _firestore
          .collection('properties')
          .where('ownerId', isEqualTo: ownerId)
          .get();

      return querySnapshot.docs
          .map((doc) => PropertyModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      DebugLogger.error('Failed to get properties by owner: $ownerId', e);
      throw Exception('Error loading your properties: ${e.toString()}');
    }
  }

  // Create a mock property for development mode
  PropertyModel _getMockProperty(String id) {
    // Use a consistent seed based on the ID to get the same property for the same ID
    final idHash = id.hashCode;
    final isFeatured = idHash % 3 == 0;
    final isForSale = idHash % 2 == 0;

    return PropertyModel(
      id: id,
      title: 'Mock Property #${idHash.abs() % 1000}',
      description:
          'This is a detailed description of this property. It includes multiple features and highlights of the property.',
      price: 100000 + (idHash.abs() % 900000),
      location: 'Sample Location #${idHash.abs() % 10}',
      bedrooms: 1 + (idHash.abs() % 5),
      bathrooms: 1 + (idHash.abs() % 3),
      area: 800 + (idHash.abs() % 2000),
      images: [
        'https://images.unsplash.com/photo-1568605114967-8130f3a36994?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
        'https://images.unsplash.com/photo-1560184897-ae75f418493e?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
      ],
      featured: isFeatured,
      isApproved: true,
      listingType: isForSale ? 'sale' : 'rent',
      amenities: ['Pool', 'Garden', 'Garage', 'Security System'],
      ownerId: 'dev-user-123',
      createdAt: DateTime.now().subtract(Duration(days: idHash.abs() % 30)),
      updatedAt: DateTime.now().subtract(Duration(days: idHash.abs() % 15)),
      type: PropertyType.house,
      status: PropertyStatus.available,
      propertyType: 'House',
    );
  }

  // Create mock properties for development mode
  List<PropertyModel> _getMockProperties() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    return [
      PropertyModel(
        id: 'dev-$timestamp-1',
        title: 'Luxury Villa with Pool',
        description: 'Beautiful 4-bedroom villa with a private pool and garden',
        price: 750000,
        location: 'Palm Beach, FL',
        bedrooms: 4,
        bathrooms: 3,
        area: 2800,
        images: [
          'https://images.unsplash.com/photo-1613490493576-7fde63acd811?ixlib=rb-4.0.3',
          'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?ixlib=rb-4.0.3',
        ],
        featured: true,
        isApproved: true,
        listingType: 'sale',
        amenities: ['Pool', 'Garden', 'Garage', 'Security System'],
        ownerId: 'dev-user-123',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now().subtract(const Duration(days: 3)),
        type: PropertyType.house,
        status: PropertyStatus.available,
        propertyType: 'House',
      ),
      PropertyModel(
        id: 'dev-$timestamp-2',
        title: 'Modern Downtown Apartment',
        description: 'Sleek 2-bedroom apartment in the heart of downtown',
        price: 2500,
        location: 'Downtown, NY',
        bedrooms: 2,
        bathrooms: 2,
        area: 1200,
        images: [
          'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?ixlib=rb-4.0.3',
        ],
        featured: false,
        isApproved: true,
        listingType: 'rent',
        amenities: ['Gym', 'Doorman', 'Elevator', 'Parking'],
        ownerId: 'dev-user-123',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        type: PropertyType.apartment,
        status: PropertyStatus.available,
        propertyType: 'Apartment',
      ),
      PropertyModel(
        id: 'dev-$timestamp-3',
        title: 'Beachfront Property',
        description: 'Stunning beachfront property with panoramic ocean views',
        price: 1200000,
        location: 'Malibu, CA',
        bedrooms: 5,
        bathrooms: 4,
        area: 3500,
        images: [
          'https://images.unsplash.com/photo-1513584684374-8bab748fbf90?ixlib=rb-4.0.3',
        ],
        featured: true,
        isApproved: false, // Not approved
        listingType: 'sale',
        amenities: ['Private Beach', 'Hot Tub', 'Home Theater', 'Wine Cellar'],
        ownerId: 'dev-user-456',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 12)),
        type: PropertyType.house,
        status: PropertyStatus.pending,
        propertyType: 'House',
      ),
      PropertyModel(
        id: 'dev-$timestamp-4',
        title: 'Family Home in Suburbs',
        description: 'Spacious family home with large backyard in quiet suburb',
        price: 450000,
        location: 'Naperville, IL',
        bedrooms: 4,
        bathrooms: 2,
        area: 2200,
        images: [
          'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?ixlib=rb-4.0.3',
        ],
        featured: false,
        isApproved: true,
        listingType: 'sale',
        amenities: ['Backyard', 'Finished Basement', 'Deck', 'Fireplace'],
        ownerId: 'dev-user-123',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        updatedAt: DateTime.now().subtract(const Duration(days: 8)),
        type: PropertyType.house,
        status: PropertyStatus.available,
        propertyType: 'House',
      ),
      PropertyModel(
        id: 'dev-$timestamp-5',
        title: 'Cozy Studio Apartment',
        description: 'Perfect starter apartment near university campus',
        price: 1100,
        location: 'Cambridge, MA',
        bedrooms: 0,
        bathrooms: 1,
        area: 500,
        images: [
          'https://images.unsplash.com/photo-1502672023488-70e25813eb80?ixlib=rb-4.0.3',
        ],
        featured: false,
        isApproved: true,
        listingType: 'rent',
        amenities: ['Utilities Included', 'Laundry', 'Wifi'],
        ownerId: 'dev-user-789',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        type: PropertyType.apartment,
        status: PropertyStatus.available,
        propertyType: 'Studio',
      ),
    ];
  }
}
