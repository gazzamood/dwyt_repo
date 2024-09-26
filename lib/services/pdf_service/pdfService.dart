import 'package:file_picker/file_picker.dart';

class PdfService {
  // Metodo per selezionare un file PDF
  static Future<String?> pickPdfFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.isNotEmpty) {
      return result.files.single.path; // Restituisce il percorso del file PDF selezionato
    } else {
      return null; // Nessun file selezionato o l'utente ha annullato
    }
  }
}
