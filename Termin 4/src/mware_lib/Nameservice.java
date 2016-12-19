package mware_lib;
import mware_lib.interfaces.NameServiceInterface;

public class NameService implements NameServiceInterface{
    /**
     * Mit der Funktion sollen sich Objekte beim Namensdienst registrieren
     *
     * @param servant die Objektreferenz
     * @param name    der Name des Objekts
     */
    @Override
    public void rebind(String servant, String name) {

    }

    /**
     * Liefert eine Objektreferenz zu einem Namen zurück
     *
     * @param name der Name der Objektrefrenz
     * @return die Objektreferenz zum übergebenen Namen
     */
    @Override
    public String resolve(String name) {
        return null;
    }
}
