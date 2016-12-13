package mware_lib;

/**
 * Stellt den Namensdinest für die Middleware zur Verfügung
 * Möglichkeit: Objektreferezen werden an Hand des übergebenen Namens identifiziert
 */
interface NameServiceInterface {
    /**
     * Mit der Funktion sollen sich Objekte beim Namensdienst registrieren
     * @param servant die Objektreferenz
     * @param name der Name des Objekts
     */
    void rebind(String servant, String name);

    /**
     * Liefert eine Objektreferenz zu einem Namen zurück
     * @param name der Name der Objektrefrenz
     * @return die Objektreferenz zum übergebenen Namen
     */
    String resolve(String name);
}
