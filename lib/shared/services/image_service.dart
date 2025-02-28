import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:mime/mime.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';

class ImageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();
  
  // Upload a single image to Firebase Storage
  Future<String> uploadImage(File file, {String? folder}) async {
    try {
      final String fileName = '${const Uuid().v4()}${path.extension(file.path)}';
      final String storagePath = folder != null 
          ? '$folder/$fileName' 
          : 'images/$fileName';
      
      final Reference ref = _storage.ref().child(storagePath);
      
      // Check mime type
      final mimeType = lookupMimeType(file.path);
      if (mimeType == null || !mimeType.startsWith('image/')) {
        throw Exception('Invalid image format');
      }
      
      // Handle metadata
      final SettableMetadata metadata = SettableMetadata(
        contentType: mimeType,
        customMetadata: {
          'uploaded': DateTime.now().toIso8601String(),
          'originalName': path.basename(file.path),
        },
      );
      
      // Upload file
      await ref.putFile(file, metadata);
      
      // Get download URL
      final String downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Image upload failed: $e');
    }
  }
  
  // Upload multiple property images
  Future<List<String>> uploadPropertyImages(List<File> files) async {
    try {
      List<String> downloadUrls = [];
      
      for (var file in files) {
        final url = await uploadImage(file, folder: 'properties');
        downloadUrls.add(url);
      }
      
      return downloadUrls;
    } catch (e) {
      throw Exception('Property images upload failed: $e');
    }
  }
  
  // Pick a single image
  Future<File?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } on PlatformException catch (e) {
      throw Exception('Image picking failed: ${e.message}');
    }
  }
  
  // Pick multiple images
  Future<List<File>> pickMultiImage({int maxImages = 10}) async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (pickedFiles.isEmpty) return [];
      
      // Enforce max images limit
      final filesToProcess = pickedFiles.length > maxImages 
          ? pickedFiles.sublist(0, maxImages) 
          : pickedFiles;
      
      return filesToProcess.map((xFile) => File(xFile.path)).toList();
    } on PlatformException catch (e) {
      throw Exception('Multiple image picking failed: ${e.message}');
    }
  }
  
  // Delete an image from Firebase Storage
  Future<void> deleteImage(String imageUrl) async {
    try {
      // Extract file path from URL
      final uri = Uri.parse(imageUrl);
      String filePath = uri.path;
      
      // Remove the initial /v0/b/PROJECT_ID/o/ part and decode the URL
      if (filePath.contains('/o/')) {
        filePath = filePath.split('/o/')[1];
        filePath = Uri.decodeComponent(filePath).split('?')[0];
      }
      
      // Delete the file
      await _storage.ref().child(filePath).delete();
    } catch (e) {
      throw Exception('Image deletion failed: $e');
    }
  }
  
  // Validate image aspect ratio (e.g., for property photos requiring 16:9)
  static Future<bool> validateImageAspectRatio(
    File imageFile, 
    {double targetRatio = 16/9, double tolerance = 0.2}
  ) async {
    try {
      final bytes = await imageFile.readAsBytes();
      // Import flutter/painting.dart for decodeImageFromList
      final image = await decodeImageFromList(bytes);
      
      final aspectRatio = image.width / image.height;
      
      return (aspectRatio >= targetRatio - tolerance && 
              aspectRatio <= targetRatio + tolerance);
    } catch (e) {
      throw Exception('Image validation failed: $e');
    }
  }
}
