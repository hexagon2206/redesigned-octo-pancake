/**
 * Stellt für die Anwenundg den Anlaufpunkt zur Auflösung von Namen auf Objektrferenz da.
 * Es ist möglich sich beim Namensdienst mit einem Namen und einer Referenz zu registrieren und später über eine Schnittstelle, Anfragen zur Namensauflösung zu stellen
 */

public class Nameservice implements mware_lib.Nameservice {

    /**
     * Mit der Funktion sollen sich Objekte beim Namensdienst registrieren
     *
     * @param servant die Objektreferenz
     * @param name    der Name des Objekts
     */
    @Override
    public void rebind(Object servant, String name) {

    }

    /**
     * Liefert eine Objektreferenz zu einem Namen zurück
     *
     * @param name der Name der Objektrefrenz
     * @return die Objektreferenz zum übergebenen Namen
     */
    @Override
    public Object resolve(String name) {
        return null;
    }
}
