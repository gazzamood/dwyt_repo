import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
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
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('Errore: Utente non autenticato. Effettua l\'accesso prima di caricare il file.');
        return null;
      }

      final File imageFile = File(photo.path);
      if (!imageFile.existsSync()) {
        print('File does not exist at the specified path.');
        return null;
      }

      final String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final Reference storageRef = FirebaseStorage.instance.ref().child('uploads/$fileName');

      final UploadTask uploadTask = storageRef.putFile(imageFile);
      final TaskSnapshot snapshot = await uploadTask.whenComplete(() => null);

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