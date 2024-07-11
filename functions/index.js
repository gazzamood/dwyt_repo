const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.sendAlertToUsers = functions.firestore
  .document('alerts/{alertId}')
  .onCreate(async (snapshot, context) => {
    const alertData = snapshot.data();
    const message = {
      notification: {
        title: 'Messaggio di allerta!',
        body: alertData.message,
      }
    };

    try {
      // Ottieni tutti i token FCM degli utenti registrati
      const usersSnapshot = await admin.firestore().collection('users').get();
      const tokens = [];
      usersSnapshot.forEach(doc => {
        const token = doc.data().fcmToken;
        if (token) {
          tokens.push(token);
        }
      });

      // Invia la notifica a tutti i dispositivi
      await admin.messaging().sendToDevice(tokens, message);
      console.log('Notifica push inviata con successo:', message);
    } catch (error) {
      console.error('Errore durante l\'invio della notifica push:', error);
    }
  });
