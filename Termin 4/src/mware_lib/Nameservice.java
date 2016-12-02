package mware_lib;

/**
 * Created by Jolly Joker on 02.12.2016.
 */
public interface Nameservice {
    /**
     * Mit der Funktion sollen sich Objekte beim Namensdienst registrieren
     * @param servant die Objektreferenz
     * @param name der Name des Objekts
     */
    void rebind(Object servant, String name);

    /**
     * Liefert eine Objektreferenz zu einem Namen zurück
     * @param name der Name der Objektrefrenz
     * @return die Objektreferenz zum übergebenen Namen
     */
    Object resolve(String name);
}
