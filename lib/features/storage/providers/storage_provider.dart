import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class StorageProvider extends ChangeNotifier {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  bool _isLoading = false;
  String? _error;
  double _uploadProgress = 0.0;  // Add upload progress tracking
  
  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get uploadProgress => _uploadProgress;  // Add getter for progress

  // Upload a file to Firebase Storage
  Future<String> uploadFile(File file, String destination) async {
    _isLoading = true;
    _error = null;
    _uploadProgress = 0.0;  // Reset progress
    notifyListeners();
    
    try {
      final ref = _storage.ref().child(destination);
      final uploadTask = ref.putFile(file);
      
      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
        notifyListeners();
      });
      
      // Wait for the upload to complete
      final snapshot = await uploadTask;
      
      // Get the download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      _isLoading = false;
      _uploadProgress = 1.0;  // Set progress to complete
      notifyListeners();
      
      return downloadUrl;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      throw Exception('Failed to upload file: $e');
    }
  }
  
  // Specialized method for property images
  Future<String> uploadPropertyImage(File file) async {
    final fileName = DateTime.now().millisecondsSinceEpoch.toString() + '_' + file.path.split('/').last;
    final destination = 'property_images/$fileName';
    return await uploadFile(file, destination);
  }
  
  // Delete a file from Firebase Storage
  Future<void> deleteFile(String fileUrl) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Get reference from the URL
      final ref = _storage.refFromURL(fileUrl);
      
      // Delete the file
      await ref.delete();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      throw Exception('Failed to delete file: $e');
    }
  }

  void resetState() {
    _isLoading = false;
    _error = null;
    _uploadProgress = 0.0;  // Reset progress when state is reset
    notifyListeners();
  }
}
