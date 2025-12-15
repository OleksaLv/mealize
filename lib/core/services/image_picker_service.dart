import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

class ImagePickerService {
  final ImagePicker _picker = ImagePicker();

  Future<String?> pickImage({required ImageSource source}) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1000,
        imageQuality: 70,
      );

      if (pickedFile == null) return null;

      final directory = await getApplicationDocumentsDirectory();
      
      final String imagesDirPath = '${directory.path}/user_images';
      final Directory imagesDir = Directory(imagesDirPath);
      
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

     final String fileExt = path.extension(pickedFile.path);
      final String uniqueFileName = '${const Uuid().v4()}$fileExt';
      final String permanentPath = '$imagesDirPath/$uniqueFileName';

      final File tempFile = File(pickedFile.path);
      final File permanentFile = await tempFile.copy(permanentPath);

      return permanentFile.path;

    } catch (e) {
      debugPrint('Image picking and saving failed: $e');
      return null;
    }
  }

  Future<String?> showImageSourceDialog(BuildContext context) async {
    final result = await showModalBottomSheet<ImageSource?>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Галерея'),
                onTap: () {
                  Navigator.of(context).pop(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Камера'),
                onTap: () {
                  Navigator.of(context).pop(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );

    if (result != null) {
      return await pickImage(source: result);
    }
    return null;
  }
}