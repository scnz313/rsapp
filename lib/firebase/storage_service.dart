
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../core/utils/dev_utils.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Upload a single property image and return its URL
  Future<String?> uploadPropertyImage(File image, String propertyId) async {
    try {
      // Use mock image in dev mode
      if (DevUtils.isDev && DevUtils.bypassAuth) {
        DevUtils.log('Using mock image URL in dev mode');
        await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay
        return 'https://images.unsplash.com/photo-1580587771525-78b9dba3b914?w=800';
      }
      
      // Verify authentication
      final user = _auth.currentUser;
      if (user == null) return null;
      
      // Generate a unique filename using timestamp
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.path.split('/').last}';
      
      // Create reference to the file location in Firebase Storage
      final storageRef = _storage.ref()
          .child('property_images')
          .child(propertyId)
          .child(fileName);
      
      // Upload the file
      final uploadTask = storageRef.putFile(
        image,
        SettableMetadata(
          contentType: 'image/jpeg', // Set appropriate content type
          customMetadata: {
            'uploadedBy': user.uid,
            'propertyId': propertyId,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );
      
      // Wait for the upload to complete
      await uploadTask.whenComplete(() => debugPrint('Image uploaded successfully'));
      
      // Get the download URL
      final downloadUrl = await storageRef.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading property image: $e');
      return null;
    }
  }
  
  // Upload multiple property images at once
  Future<List<String>> uploadPropertyImages(List<File> images, String propertyId) async {
    List<String> imageUrls = [];
    
    try {
      // Use mock images in dev mode
      if (DevUtils.isDev && DevUtils.bypassAuth) {
        DevUtils.log('Using mock image URLs in dev mode');
        await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
        return List.generate(
          images.length, 
          (index) => 'https://images.unsplash.com/photo-${1580587771525 + index}-78b9dba3b914?w=800'
        );
      }
      
      // Upload each image and collect URLs
      for (final image in images) {
        final url = await uploadPropertyImage(image, propertyId);
        if (url != null) {
          imageUrls.add(url);
        }
      }
      
      return imageUrls;
    } catch (e) {
      debugPrint('Error uploading multiple property images: $e');
      return imageUrls; // Return any URLs we managed to get before the error
    }
  }
  
  // Upload a profile image
  Future<String?> uploadProfileImage(File image) async {
    try {
      // Verify authentication
      final user = _auth.currentUser;
      if (user == null && !(DevUtils.isDev && DevUtils.bypassAuth)) return null;
      
      final userId = user?.uid ?? DevUtils.devUserId;
      
      // Generate a unique filename
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      // Create reference to the file location
      final storageRef = _storage.ref()
          .child('profile_images')
          .child(userId)
          .child(fileName);
      
      // Upload the file
      final uploadTask = storageRef.putFile(
        image,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'userId': userId,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );
      
      // Wait for the upload to complete
      await uploadTask.whenComplete(() => debugPrint('Profile image uploaded successfully'));
      
      // Get the download URL
      final downloadUrl = await storageRef.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading profile image: $e');
      return null;
    }
  }
  
  // Delete a property image by URL
  Future<bool> deletePropertyImage(String imageUrl, String propertyId) async {
    try {
      // Verify authentication
      final user = _auth.currentUser;
      if (user == null && !(DevUtils.isDev && DevUtils.bypassAuth)) return false;
      
      // Extract the file path from the URL
      final ref = _storage.refFromURL(imageUrl);
      
      // Delete the file
      await ref.delete();
      
      return true;
    } catch (e) {
      debugPrint('Error deleting property image: $e');
      return false;
    }
  }
  
  // Helper method to get image from camera or gallery
  Future<File?> getImageFromSource(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1920,  // Resize to reasonable dimensions
        maxHeight: 1080,
        imageQuality: 85, // Compress to reduce file size
      );
      
      if (pickedFile == null) return null;
      
      return File(pickedFile.path);
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }
  
  // Delete all images for a property
  Future<bool> deleteAllPropertyImages(String propertyId) async {
    try {
      // Verify authentication
      final user = _auth.currentUser;
      if (user == null && !(DevUtils.isDev && DevUtils.bypassAuth)) return false;
      
      // List all files in the property directory
      final ListResult result = await _storage.ref()
          .child('property_images')
          .child(propertyId)
          .listAll();
      
      // Delete each file
      for (final Reference ref in result.items) {
        await ref.delete();
      }
      
      return true;
    } catch (e) {
      debugPrint('Error deleting all property images: $e');
      return false;
    }
  }
}
