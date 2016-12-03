package mware_lib;

/**
 * Created by Jolly Joker on 02.12.2016.
 */
public abstract class ObjectBroker {
    /**
     * Liefert das Objekt zurück, das als zentrales Objekt der Middleware aus Anwendungsschicht dient
     *
     * @param host der Host auf dem der Namensdienst läuft
     * @param port der port auf dem der Namensdienst hört
     * @param debug gibt an, ob Debuginformationen angezeigt werden sollen oder nicht
     * @return das zentrale Objekt der Middleware
     */
    public static ObjectBroker init(String host, int port, boolean debug){
        // TODO: Implementierung
        return null;
    }

    /**
     * Liefert den Namensdienst
     * @return das Namensdienstobjekt
     */
    abstract Nameservice getNameservice();

    /**
     * Fährt das System herunter
     */
    abstract void shutDown();
}
