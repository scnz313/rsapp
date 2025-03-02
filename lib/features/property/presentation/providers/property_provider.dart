import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/core/utils/dev_utils.dart'; // Add this import for DevUtils
import '/features/property/data/models/property_model.dart';
import '../../data/property_repository.dart';

class PropertyProvider with ChangeNotifier {
  final PropertyRepository _repository;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  bool _isLoading = false;
  List<PropertyModel> _properties = [];
  List<PropertyModel> _featuredProperties = [];
  List<PropertyModel> _recentProperties = [];
  List<PropertyModel> _searchResults = [];
  PropertyModel? _selectedProperty;
  String? _error;
  Map<String, dynamic> _filters = {};

  PropertyProvider(this._repository);
  
  // Getters
  bool get isLoading => _isLoading;
  List<PropertyModel> get properties => _properties;
  List<PropertyModel> get featuredProperties => _featuredProperties;
  List<PropertyModel> get recentProperties => _recentProperties;
  List<PropertyModel> get searchResults => _searchResults;
  PropertyModel? get selectedProperty => _selectedProperty;
  String? get error => _error;
  
  // Add searchProperties method that was missing
  Future<void> searchProperties(String query) async {
    _setLoading(true);
    try {
      _searchResults = await _repository.searchProperties(query);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }
  
  // Add applyFilters method that was missing
  void applyFilters(Map<String, dynamic> filters) {
    _filters = filters;
    fetchProperties(filters: _filters);
  }

  // Reset filters
  void resetFilters() {
    _filters = {};
    fetchProperties();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  Future<void> fetchProperties({Map<String, dynamic>? filters}) async {
    _setLoading(true);
    try {
      _properties = await _repository.fetchProperties(filters: filters); // Changed from getProperties to fetchProperties
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }
  
  Future<void> fetchFeaturedProperties() async {
    _setLoading(true);
    try {
      _featuredProperties = await _repository.fetchFeaturedProperties(); // Changed from getFeaturedProperties to fetchFeaturedProperties
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Fetch recent properties
  Future<void> fetchRecentProperties() async {
    _setLoading(true);
    try {
      // This is important - we need to also include dev mode properties
      if (DevUtils.isDev && DevUtils.bypassAuth) {
        // When in dev mode, make sure recently added dev properties appear in the list
        _recentProperties = _properties;
        
        // If no properties exist yet, create a placeholder
        if (_recentProperties.isEmpty && _properties.isEmpty) {
          debugPrint('Creating placeholder properties for dev mode');
          // No need to create placeholders - just log it
        }
      } else {
        // Normal fetch from repository
        _recentProperties = await _repository.fetchProperties(
          filters: {'sortBy': 'createdAt', 'limit': 10}
        );
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error fetching recent properties: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  Future<PropertyModel?> getPropertyById(String id) async {
    _setLoading(true);
    try {
      _selectedProperty = await _repository.getPropertyById(id);
      _error = null;
      return _selectedProperty;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _setLoading(false);
    }
  }
  
  // Add fetchPropertyById method that was missing
  Future<void> fetchPropertyById(String id) async {
    _setLoading(true);
    try {
      _selectedProperty = await _repository.getPropertyById(id);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }
  
  // Create new property with logging history
  Future<void> createProperty(Map<String, dynamic> propertyData) async {
    _setLoading(true);
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      // Add owner information and timestamps
      propertyData['ownerId'] = currentUser.uid;
      propertyData['ownerEmail'] = currentUser.email;
      propertyData['createdAt'] = FieldValue.serverTimestamp();
      propertyData['updatedAt'] = FieldValue.serverTimestamp();
      
      // Create property document
      final docRef = await _firestore.collection('properties').add(propertyData);
      
      // Log initial creation in history subcollection
      await docRef.collection('history').add({
        'timestamp': FieldValue.serverTimestamp(),
        'changedBy': currentUser.email ?? currentUser.uid,
        'changedFields': ['created'],
        'action': 'create',
      });
      
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }
  
  // Update existing property with logging history
  Future<void> updateProperty(String id, Map<String, dynamic> updatedData) async {
    _setLoading(true);
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      // Add updated timestamp
      updatedData['updatedAt'] = FieldValue.serverTimestamp();
      
      // Update property document
      final docRef = _firestore.collection('properties').doc(id);
      await docRef.update(updatedData);
      
      // Log update in history subcollection
      await docRef.collection('history').add({
        'timestamp': FieldValue.serverTimestamp(),
        'changedBy': currentUser.email ?? currentUser.uid,
        'changedFields': updatedData.keys.toList(),
        'action': 'update',
      });
      
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }
  
  // Delete property with logging history
  Future<void> deleteProperty(String id) async {
    _setLoading(true);
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      // Delete property document
      final docRef = _firestore.collection('properties').doc(id);
      await docRef.delete();
      
      // Log deletion in history subcollection
      await docRef.collection('history').add({
        'timestamp': FieldValue.serverTimestamp(),
        'changedBy': currentUser.email ?? currentUser.uid,
        'changedFields': ['deleted'],
        'action': 'delete',
      });
      
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }
  
  // Get property history - returns list of changes
  Future<List<Map<String, dynamic>>> getPropertyHistory(String id) async {
    _setLoading(true);
    try {
      final historySnapshot = await _firestore
          .collection('properties')
          .doc(id)
          .collection('history')
          .orderBy('timestamp', descending: true)
          .get();
      
      final history = historySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'timestamp': data['timestamp'] as Timestamp,
          'changedBy': data['changedBy'] as String,
          'changedFields': List<String>.from(data['changedFields'] ?? []),
          'action': data['action'] as String,
        };
      }).toList();
      
      return history;
    } catch (e) {
      _error = e.toString();
      return [];
    } finally {
      _setLoading(false);
    }
  }
  
  // Schedule property for publication
  Future<void> scheduleProperty(String id, DateTime publishDate) async {
    _setLoading(true);
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      // Update property with publication date
      final docRef = _firestore.collection('properties').doc(id);
      await docRef.update({
        'publishDate': publishDate,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Log scheduling in history
      await docRef.collection('history').add({
        'timestamp': FieldValue.serverTimestamp(),
        'changedBy': currentUser.email ?? currentUser.uid,
        'changedFields': ['publishDate'],
        'action': 'schedule',
        'details': {
          'publishDate': publishDate,
        }
      });
      
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }
  
  // Mark property as sold/rented
  Future<void> changePropertyStatus(String id, PropertyStatus status) async {
    _setLoading(true);
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      // Update property status
      final docRef = _firestore.collection('properties').doc(id);
      await docRef.update({
        'status': status.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Log status change in history
      await docRef.collection('history').add({
        'timestamp': FieldValue.serverTimestamp(),
        'changedBy': currentUser.email ?? currentUser.uid,
        'changedFields': ['status'],
        'action': 'statusChange',
        'details': {
          'newStatus': status.toString().split('.').last,
        }
      });
      
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }
  
  // Feature/unfeature a property
  Future<void> toggleFeatureProperty(String id, bool isFeatured) async {
    _setLoading(true);
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      // Update property featured status
      final docRef = _firestore.collection('properties').doc(id);
      await docRef.update({
        'featured': isFeatured,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Log feature change in history
      await docRef.collection('history').add({
        'timestamp': FieldValue.serverTimestamp(),
        'changedBy': currentUser.email ?? currentUser.uid,
        'changedFields': ['featured'],
        'action': isFeatured ? 'feature' : 'unfeature',
      });
      
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }
  
  // Report analytics for property views
  Future<void> recordPropertyView(String id) async {
    try {
      // Increment view count
      final docRef = _firestore.collection('properties').doc(id);
      await docRef.update({
        'viewCount': FieldValue.increment(1),
      });
      
      // Add to analytics collection
      await _firestore.collection('property_analytics').add({
        'propertyId': id,
        'action': 'view',
        'timestamp': FieldValue.serverTimestamp(),
        'userId': _auth.currentUser?.uid ?? 'anonymous',
        'deviceInfo': {
          'platform': kIsWeb ? 'web' : 'app',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      });
      
    } catch (e) {
      // Don't set loading or error for analytics - silent failure is okay
      debugPrint('Error recording view: $e'); // Changed from print to debugPrint
    }
  }
  
  // Compare two properties (useful for showing comparisons)
  Map<String, dynamic> compareProperties(PropertyModel prop1, PropertyModel prop2) {
    return {
      'price': {
        'difference': (prop1.price - prop2.price),
        'percentageDiff': '${((prop1.price - prop2.price) / prop2.price * 100).toStringAsFixed(1)}%', 
      },
      'area': {
        'difference': (prop1.area - prop2.area),
        'percentageDiff': '${((prop1.area - prop2.area) / prop2.area * 100).toStringAsFixed(1)}%', 
      },
      'bedrooms': {
        'difference': (prop1.bedrooms - prop2.bedrooms),
      },
      'bathrooms': {
        'difference': (prop1.bathrooms - prop2.bathrooms),
      },
      'pricePerSqFt': {
        'prop1': (prop1.price / prop1.area).toStringAsFixed(2),
        'prop2': (prop2.price / prop2.area).toStringAsFixed(2),
        'difference': ((prop1.price / prop1.area) - (prop2.price / prop2.area)).toStringAsFixed(2),
        'percentageDiff': '${(((prop1.price / prop1.area) - (prop2.price / prop2.area)) / 
            (prop2.price / prop2.area) * 100).toStringAsFixed(1)}%',
      },
    };
  }

  // Change print to debugPrint
  void reportError(String message, dynamic error) {
    debugPrint('$message: $error');
  }
  
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Add new method for property creation with images - revised implementation
  Future<void> createPropertyWithImages(PropertyModel property, List<File> images) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // First upload images and get URLs
      final List<String> imageUrls = await uploadMultipleImages(images);
      
      // Copy the property with the correct image URLs
      final updatedProperty = property.copyWith(images: imageUrls);
      
      // Add the property data to Firestore
      await addNewProperty(updatedProperty.toMap());
      
      // Update local list
      final newProperty = property.copyWith(images: imageUrls);
      _properties = [newProperty, ..._properties];
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error creating property: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
  
  // *** FIX: Add method for uploading multiple images since repository doesn't have it ***
  Future<List<String>> uploadMultipleImages(List<File> images) async {
    final List<String> urls = [];
    
    try {
      for (final image in images) {
        final url = await _repository.uploadImage(image);
        urls.add(url);
      }
      return urls;
    } catch (e) {
      debugPrint('Error uploading images: $e');
      rethrow;
    }
  }

  // Add new method for adding property
  Future<void> addNewProperty(Map<String, dynamic> propertyData) async {
    _setLoading(true);
    try {
      // Check if in dev mode first
      if (DevUtils.isDev && DevUtils.bypassAuth) {
        DevUtils.log('Using dev mode for property creation');
        
        // In dev mode, we don't need to check for current user
        // Add dev mode metadata
        propertyData['ownerId'] = DevUtils.devUserId;
        propertyData['ownerEmail'] = DevUtils.devUserEmail;
        propertyData['createdAt'] = DateTime.now(); // Use normal DateTime instead of FieldValue
        propertyData['updatedAt'] = DateTime.now();
        propertyData['isDev'] = true; // Mark as dev data
        
        // Simulate successful creation
        await Future.delayed(const Duration(milliseconds: 500)); // Add small delay for UI feedback
        
        // Add to the local list with a fake ID
        final fakeId = 'dev-${DateTime.now().millisecondsSinceEpoch}';
        propertyData['id'] = fakeId;
        
        // Convert map to PropertyModel and add to list - use the correct factory method
        try {
          // Convert string type/status to the appropriate enum values
          final PropertyType propertyType = _getPropertyTypeFromString(propertyData['type'] ?? 'house');
          final PropertyStatus propertyStatus = _getPropertyStatusFromString(propertyData['status'] ?? 'available');
          
          final newProperty = PropertyModel(
            id: fakeId,
            title: propertyData['title'],
            price: propertyData['price'],
            description: propertyData['description'],
            location: propertyData['location'],
            images: List<String>.from(propertyData['images'] ?? []),
            bedrooms: propertyData['bedrooms'],
            bathrooms: propertyData['bathrooms'],
            area: propertyData['area'],
            propertyType: propertyData['propertyType'],
            listingType: propertyData['listingType'],
            latitude: propertyData['latitude'],
            longitude: propertyData['longitude'],
            createdAt: propertyData['createdAt'] ?? DateTime.now(),
            updatedAt: propertyData['updatedAt'] ?? DateTime.now(),
            type: propertyType, // Use the enum value
            status: propertyStatus, // Use the enum value
          );
          
          _properties = [newProperty, ..._properties];
          _recentProperties = [newProperty, ..._recentProperties];
          
          // Notify listeners to update UI
          notifyListeners();
        } catch (e) {
          debugPrint('Error creating property model: $e');
        }
        
        _error = null;
        _setLoading(false);
        return;
      }
      
      // Existing code for production mode
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      // Add owner information and timestamps
      propertyData['ownerId'] = currentUser.uid;
      propertyData['ownerEmail'] = currentUser.email;
      propertyData['createdAt'] = FieldValue.serverTimestamp();
      propertyData['updatedAt'] = FieldValue.serverTimestamp();
      
      // Create property document
      final docRef = await _firestore.collection('properties').add(propertyData);
      
      // Log initial creation in history subcollection
      await docRef.collection('history').add({
        'timestamp': FieldValue.serverTimestamp(),
        'changedBy': currentUser.email ?? currentUser.uid,
        'changedFields': ['created'],
        'action': 'create',
      });
      
      _error = null;
      
      // Reload properties to get the newly added one
      await fetchProperties();
      
    } catch (e) {
      _error = e.toString();
      debugPrint('Error adding property: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Add these helper methods to convert strings to enum values
  PropertyType _getPropertyTypeFromString(String type) {
    switch(type.toLowerCase()) {
      case 'house': return PropertyType.house;
      case 'apartment': return PropertyType.apartment;
      case 'condo': return PropertyType.condo;
      case 'land': return PropertyType.land;
      case 'commercial': return PropertyType.commercial;
      default: return PropertyType.house;
    }
  }

  PropertyStatus _getPropertyStatusFromString(String status) {
    switch(status.toLowerCase()) {
      case 'available': return PropertyStatus.available;
      case 'pending': return PropertyStatus.pending;
      case 'sold': return PropertyStatus.sold;
      case 'rented': return PropertyStatus.rented;
      default: return PropertyStatus.available;
    }
  }
}
