import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import '/core/utils/dev_utils.dart'; // Add this import

class StorageProvider extends ChangeNotifier {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  bool _isLoading = false;
  double _uploadProgress = 0.0;
  String? _error;

  bool get isLoading => _isLoading;
  double get uploadProgress => _uploadProgress;
  String? get error => _error;

  /// Upload an image file to Firebase Storage with dev mode fallback
  Future<String> uploadImage(File file) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';
    final destination = 'images/$fileName';
    return uploadFile(file, destination);
  }

  /// Upload a file to Firebase Storage with dev mode fallback
  Future<String> uploadFile(File file, String destination) async {
    _isLoading = true;
    _uploadProgress = 0;
    _error = null;
    notifyListeners();

    try {
      // In dev mode, bypass actual Firebase upload if configured
      if (DevUtils.isDev && DevUtils.bypassAuth) {
        DevUtils.log('Using mock file upload for: ${file.path}');
        
        // Simulate upload delay and progress updates
        for (int i = 1; i <= 10; i++) {
          await Future.delayed(const Duration(milliseconds: 100));
          _uploadProgress = i / 10;
          notifyListeners();
        }
        
        // Return a mock URL that looks legitimate
        final mockUrl = 'https://firebasestorage.example.com/dev-mode/${path.basename(file.path)}?alt=media';
        
        _isLoading = false;
        _uploadProgress = 1.0;
        notifyListeners();
        return mockUrl;
      }
      
      // Normal Firebase Storage upload
      final ref = _storage.ref().child(destination);
      
      // Create upload task
      final uploadTask = ref.putFile(file);
      
      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
        notifyListeners();
      });
      
      // Wait for upload to complete
      await uploadTask.whenComplete(() => null);
      
      // Get download URL
      final downloadUrl = await ref.getDownloadURL();
      
      _isLoading = false;
      _uploadProgress = 1.0;
      notifyListeners();
      
      return downloadUrl;
    } catch (e) {
      DevUtils.log('Error uploading file: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      
      // Fallback in case of error - use a placeholder in development
      if (DevUtils.isDev) {
        return 'https://via.placeholder.com/800x600?text=Dev+Mode+Image';
      }
      
      throw Exception('Failed to upload file: $e');
    }
  }

  /// Delete a file from Firebase Storage
  Future<void> deleteFile(String fileUrl) async {
    // Implementation stays the same but with dev mode check
    if (DevUtils.isDev && DevUtils.bypassAuth) {
      DevUtils.log('Mock delete file: $fileUrl');
      return;
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Get the file reference from the URL
      final ref = _storage.refFromURL(fileUrl);
      
      // Delete the file
      await ref.delete();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      throw Exception('Failed to delete file: $e');
    }
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
