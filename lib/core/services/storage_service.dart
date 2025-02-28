import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import '../utils/logger.dart';

class StorageService {
  static const String _tag = 'StorageService';
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> uploadPropertyImage(String propertyId, File file) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('properties/$propertyId/$fileName');
      
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask;
      
      final downloadUrl = await snapshot.ref.getDownloadURL();
      AppLogger.i(_tag, 'Image uploaded successfully: $downloadUrl');
      
      return downloadUrl;
    } catch (e) {
      AppLogger.e(_tag, 'Error uploading image', e);
      return null;
    }
  }

  Future<String?> uploadProfileImage(String userId, File file) async {
    try {
      final fileName = 'profile.jpg';
      final ref = _storage.ref().child('users/$userId/profile/$fileName');
      
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask;
      
      final downloadUrl = await snapshot.ref.getDownloadURL();
      AppLogger.i(_tag, 'Profile image uploaded successfully: $downloadUrl');
      
      return downloadUrl;
    } catch (e) {
      AppLogger.e(_tag, 'Error uploading profile image', e);
      return null;
    }
  }
}
