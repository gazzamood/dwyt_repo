/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {onRequest} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });


const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.sendAlertToUsers = functions.https.onCall(async (data, context) => {
  // Controllo dell'autenticazione dell'utente (opzionale)
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'L\'utente deve essere autenticato.');
  }

  // Ottenere tutti i token FCM degli utenti registrati
  const usersSnapshot = await admin.firestore().collection('users').get();
  const tokens = [];
  usersSnapshot.forEach(doc => {
    const token = doc.data().fcmToken;
    if (token) {
      tokens.push(token);
    }
  });

  // Creazione del payload della notifica
  const payload = {
    notification: {
      title: 'Messaggio di Allerta',
      body: data.message
    }
  };

  // Invio della notifica a tutti i dispositivi
  await admin.messaging().sendToDevice(tokens, payload);

  return { success: true };
});