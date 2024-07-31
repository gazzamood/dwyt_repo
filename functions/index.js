const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

// Funzione che viene eseguita ogni minuto per controllare la posizione degli utenti
exports.periodicUserCheck = functions.pubsub.schedule('every 1 minutes').onRun(async (context) => {
    console.log('Esecuzione del controllo periodico degli utenti');
    await checkUserNotifications();
    return null;
});

// Funzione che viene eseguita ogni volta che viene aggiornata la tabella notifications
exports.notificationUpdateCheck = functions.firestore
    .document('notifications/{notificationId}')
    .onWrite(async (change, context) => {
        console.log('Aggiornamento nella tabella delle notifiche');
        await checkUserNotifications();
    });

// Funzione per controllare la posizione degli utenti rispetto alle notifiche
async function checkUserNotifications() {
    // Ottieni tutte le notifiche attive
    const notificationsSnapshot = await admin.firestore().collection('notifications').get();

    // Ottieni tutti gli utenti
    const usersSnapshot = await admin.firestore().collection('users').get();

    // Verifica la posizione di ciascun utente rispetto a tutte le notifiche
    let updates = [];
    notificationsSnapshot.forEach(notificationDoc => {
        const notification = notificationDoc.data();
        const notificationLat = notification.location.latitude;
        const notificationLon = notification.location.longitude;
        const radius = notification.radius; // Radius in meters
        const notificationId = notificationDoc.id;

        usersSnapshot.forEach(userDoc => {
            const user = userDoc.data();
            const userLat = user.location.latitude;
            const userLon = user.location.longitude;

            // Calcola la distanza tra l'utente e la notifica
            const distance = getDistanceFromLatLonInKm(userLat, userLon, notificationLat, notificationLon);

            if (distance <= (radius / 1000)) { // Convert radius to kilometers
                // Se l'utente è all'interno dell'area, aggiungi l'ID della notifica al campo notificationsId
                updates.push(admin.firestore().collection('users').doc(userDoc.id)
                    .update({
                        notificationsId: admin.firestore.FieldValue.arrayUnion(notificationId)
                    }));
            } else {
                console.log(`User ${userDoc.id} is outside the radius of notification ${notificationId}`);
            }
        });
    });

    // Esegui tutte le operazioni di aggiornamento degli utenti in parallelo
    await Promise.all(updates);
}

// Funzione per calcolare la distanza tra due coordinate
function getDistanceFromLatLonInKm(lat1, lon1, lat2, lon2) {
    const R = 6371; // Radius of the Earth in km
    const dLat = (lat2 - lat1) * (Math.PI / 180);
    const dLon = (lon2 - lon1) * (Math.PI / 180);
    const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
              Math.cos(lat1 * (Math.PI / 180)) * Math.cos(lat2 * (Math.PI / 180)) *
              Math.sin(dLon / 2) * Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    const distance = R * c;
    return distance;
}
