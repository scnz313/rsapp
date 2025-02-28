import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';

abstract class ImageService {
  Future<String> uploadImage(String path, List<int> bytes);
  Future<void> deleteImage(String path);
}

class FirebaseImageService implements ImageService {
  final FirebaseStorage _storage;

  FirebaseImageService([FirebaseStorage? storage])
      : _storage = storage ?? FirebaseStorage.instance;

  @override
  Future<String> uploadImage(String path, List<int> bytes) async {
    final ref = _storage.ref().child(path);
    await ref.putData(Uint8List.fromList(bytes));
    return ref.getDownloadURL();
  }

  @override
  Future<void> deleteImage(String path) async {
    await _storage.ref().child(path).delete();
  }
}
