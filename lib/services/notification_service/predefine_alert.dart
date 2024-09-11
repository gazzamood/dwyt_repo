import 'package:flutter/cupertino.dart';

class AlertService {

  final List<String> _predefinedTitledMessages = [
    'Title predefinito 1',
    'Title predefinito 2',
    'Title predefinito 3',
  ];

  final List<String> _predefinedMessages = [
    'Messaggio predefinito 1',
    'Messaggio predefinito 2',
    'Messaggio predefinito 3',
  ];

  final List<int> _predefinedRadius = [
    1,
    3,
    5,
    10,
  ];

  // Stringhe per il titolo e il messaggio
  final String _helpGenericTitle = 'Aiuto';
  final String _helpGenericMessage = 'Aiuto';

  // Stringhe per il titolo e il messaggio
  final String _HelpSaluteTitle = 'Richiesta emergenza sanitaria';
  final String _HelpSaluteMessage = 'Richiesta emergenza sanitaria';

  // Stringhe per il titolo e il messaggio
  final String _helpSicurezzaTitle = 'Allerta di sicurezza pubblica';
  final String _helpSicurezzaMessage = 'Allerta di sicurezza pubblica';

  // Metodo per ottenere i titoli predefiniti
  List<String> getPredefinedTitles() {
    return _predefinedTitledMessages;
  }

  // Metodo per ottenere i messaggi predefiniti
  List<String> getPredefinedMessages() {
    return _predefinedMessages;
  }

  // Metodo per ottenere i raggi predefiniti
  List<int> getPredefinedRadius() {
    return _predefinedRadius;
  }

  // Metodo per selezionare un titolo predefinito
  void setTitle(String selectedTitle, TextEditingController titleController) {
    titleController.text = selectedTitle;
  }

  // Metodo per selezionare un messaggio predefinito
  void setMessage(String selectedMessage, TextEditingController messageController) {
    messageController.text = selectedMessage;
  }

  // Metodo per selezionare un raggio predefinito
  void setRadius(int selectedRadius, TextEditingController radiusController) {
    radiusController.text = selectedRadius.toString();
  }


  // Metodo per settare il messaggio di aiuto generico
  Future<void> setHelpGenericMessage({
    required TextEditingController titleController,
    required TextEditingController messageController,
    required void Function(int) setRadius,
    required Future<void> Function() getLocation,
  }) async {
    titleController.text = _helpGenericTitle;
    messageController.text = _helpGenericMessage;
    setRadius(1);
    await getLocation();
  }

  // Metodo per settare il messaggio di emergenza sanitaria
  Future<void> setHelpSaluteMessage({
    required TextEditingController titleController,
    required TextEditingController messageController,
    required void Function(int) setRadius,
    required Future<void> Function() getLocation,
  }) async {
    titleController.text = _HelpSaluteTitle;
    messageController.text = _HelpSaluteMessage;
    setRadius(1);
    await getLocation();
  }

  // Metodo per settare il messaggio di allerta di sicurezza
  Future<void> setHelpSicurezzaMessage({
    required TextEditingController titleController,
    required TextEditingController messageController,
    required void Function(int) setRadius,
    required Future<void> Function() getLocation,
  }) async {
    titleController.text = _helpSicurezzaTitle;
    messageController.text = _helpSicurezzaMessage;
    setRadius(1);
    await getLocation();
  }
}
