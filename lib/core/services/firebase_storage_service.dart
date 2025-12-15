import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

class FirebaseStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Uuid _uuid = const Uuid();

  Future<String> uploadFile(File file, String folder) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User must be logged in to upload files');
      }

      final String fileExtension = path.extension(file.path);
      final String fileName = '${_uuid.v4()}$fileExtension';

      final String storagePath = 'mealize/users/${user.uid}/$folder/$fileName';

      final Reference ref = _storage.ref().child(storagePath);
      
      final UploadTask uploadTask = ref.putFile(file);
      final TaskSnapshot snapshot = await uploadTask;

      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }

  Future<void> deleteFile(String fileUrl) async {
    try {
      final Reference ref = _storage.refFromURL(fileUrl);
      await ref.delete();
    } catch (e) {
      if (e is FirebaseException && e.code == 'object-not-found') {
        return;
      }
      throw Exception('Failed to delete file: $e');
    }
  }
}