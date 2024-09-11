import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationOldService {
  // Metodo per spostare le notifiche scadute da 'notifications' a 'notificationsOld'
  Future<void> moveExpiredNotifications() async {
    final now = DateTime.now();

    try {
      // Recupera le notifiche scadute
      QuerySnapshot expiredNotifications = await FirebaseFirestore.instance
          .collection('notifications')
          .where('expirationTime',isLessThanOrEqualTo: now)
          .get();

      // Sposta le notifiche scadute in 'notificationsOld'
      for (QueryDocumentSnapshot doc in expiredNotifications.docs) {
        // Assicura che i dati siano di tipo Map<String, dynamic>
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // Copia il documento nella collezione 'notificationsOld'
        await FirebaseFirestore.instance
            .collection('notificationsOld')
            .doc(doc.id)
            .set(data);

        // Elimina il documento dalla collezione originale 'notifications'
        await doc.reference.delete();
      }

      print('Notifiche scadute spostate con successo.');
    } catch (e) {
      print('Errore durante lo spostamento delle notifiche scadute: $e');
    }
  }
}
