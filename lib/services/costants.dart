// Importante: ricordati di nominare il file secondo la convenzione Dart.
// In questo caso il file si chiamerà `constants.dart`.

class Constants {
  //utilizzati

  // URI delle API
  static const String apiKey = "AIzaSyB46qyeuCysKMD5Ka7bf5W7agt0tSr2NAE";

  // RADIUS notifiche geolocalizzate
  static const double radiusInKm = 3.0;



  // capire quali da implementare per utilizzo
  static const String apiUrl = "https://api.example.com";

  // Timeout delle richieste
  static const int apiTimeout = 30000; // in millisecondi

  // Testi statici dell'applicazione
  static const String appName = "My Awesome App";
  static const String welcomeMessage = "Benvenuto nella nostra applicazione!";

  // Colori (puoi usare il formato esadecimale per i colori)
  static const int primaryColor = 0xFF2196F3;
  static const int secondaryColor = 0xFF03A9F4;

  // Altri URL
  static const String privacyPolicyUrl = "https://example.com/privacy-policy";
  static const String termsAndConditionsUrl = "https://example.com/terms-and-conditions";

  // Dimensioni standard (padding, margin, etc.)
  static const double defaultPadding = 16.0;
  static const double defaultMargin = 16.0;

  // Limiti (ad esempio, limiti per i campi di testo)
  static const int maxUsernameLength = 20;
  static const int maxPasswordLength = 16;

  // Chiavi per la memorizzazione locale (SharedPreferences, Hive, etc.)
  static const String userTokenKey = "USER_TOKEN";
  static const String userPreferencesKey = "USER_PREFERENCES";

  // Costanti per la gestione degli errori
  static const String genericErrorMessage = "Si è verificato un errore. Riprova più tardi.";
  static const String networkErrorMessage = "Controlla la tua connessione a Internet e riprova.";
}
