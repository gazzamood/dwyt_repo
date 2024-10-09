import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class PhotoService {
  final ImagePicker _picker = ImagePicker();

  /// Opens the camera to take a new photo.
  Future<XFile?> takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      return photo;
    } catch (e) {
      print('Error taking photo: $e');
      return null;
    }
  }

  /// Opens the gallery to pick a photo.
  Future<XFile?> pickPhotoFromGallery() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.gallery);
      return photo;
    } catch (e) {
      print('Error picking photo from gallery: $e');
      return null;
    }
  }

  /// Uploads the selected photo to Firebase Storage and returns the download URL.
  /// Uploads the selected photo to Firebase Storage and returns the download URL.
  Future<String?> uploadPhoto(XFile photo) async {
    try {
      // Create a File object from the XFile path
      final File imageFile = File(photo.path);

      // Check if the file exists at the specified path
      if (!imageFile.existsSync()) {
        print('File does not exist at the specified path.');
        return null;
      }

      // Generate a unique file name based on the current timestamp
      final String fileName = DateTime.now().millisecondsSinceEpoch.toString();

      // Reference to the location in Firebase Storage where the file will be uploaded
      final Reference storageRef = FirebaseStorage.instance.ref().child('uploads/$fileName');

      // Start the upload task
      final UploadTask uploadTask = storageRef.putFile(imageFile);

      // Wait for the upload to complete and get the TaskSnapshot
      final TaskSnapshot snapshot = await uploadTask.whenComplete(() => null);

      // Get the download URL of the uploaded image
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      print('Photo uploaded successfully. Download URL: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('Error uploading photo: $e');
      if (e is FirebaseException) {
        print('FirebaseException Code: ${e.code}');
        print('FirebaseException Message: ${e.message}');
      }
      return null;
    }
  }
}