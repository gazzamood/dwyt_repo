import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PushNotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  PushNotificationService();

  Future<void> initialize() async {
    // Richiedi l'autorizzazione per le notifiche push
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    print('Autorizzazione notifiche: ${settings.authorizationStatus}');

    // Configura il gestore per le notifiche in arrivo
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Notifica push ricevuta: ${message.notification?.title}');
      // Chiamiamo la funzione di callback per gestire la notifica ricevuta
      // Nota: in questa implementazione, non stiamo aggiungendo la notifica a una lista locale
      // perché le notifiche vengono visualizzate direttamente nella sezione "Notifiche da leggere".
    });

    // Gestisci l'apertura dell'app dalla notifica push
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('App aperta tramite notifica push: ${message.notification?.title}');
      // Naviga a una schermata specifica per visualizzare il messaggio di allerta
      // Puoi implementare qui la navigazione o altre azioni desiderate
    });
  }

  // Funzione per il recupero del token di registrazione
  Future<String?> getFCMToken() async {
    return await _fcm.getToken();
  }

  // Funzione per recuperare tutti i messaggi di alert dal Firestore
  Future<List<String>> getAllAlertMessages() async {
    List<String> messages = [];

    try {
      QuerySnapshot querySnapshot = await _db.collection('alerts').get();

      for (QueryDocumentSnapshot doc in querySnapshot.docs) {
        messages.add(doc.get('message') ?? '');
      }
    } catch (e) {
      print('Errore durante il recupero degli alert: $e');
    }

    return messages;
  }
}
