package mware_lib;


public interface  ObjectBroker {
    /**
     * Liefert das Objekt zurück, das als zentrales Objekt der Middleware aus Anwendungsschicht dient
     *
     * @param host der Host auf dem der Namensdienst läuft
     * @param port der port auf dem der Namensdienst hört
     * @param debug gibt an, ob Debuginformationen angezeigt werden sollen oder nicht
     * @return das zentrale Objekt der Middleware
     */
     static ObjectBroker init(String host, int port, boolean debug){
        return null;
    }

    /**
     * Liefert den Namensdienst
     * @return das Namensdienstobjekt
     */
     Nameservice getNameservice();

    /**
     * Fährt das System herunter
     */
     void shutDown();
}
