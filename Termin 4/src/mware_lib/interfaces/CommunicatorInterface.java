package mware_lib.interfaces;

/**
 * Übernimmt für den Client und den Server die Kommunikation zur jeweiels anderen Partei
 *
 * Anwendungsfälle:
 * 1. Client stellt Anfrage
 * 2. Server benatwortet Anfrage
 * 3. Fehler wird festgestellt und an den Verursacher übertragen
 */
public interface CommunicatorInterface {

    /**
     * Führt einen Aufruf durch
     * @param reqeustID die ID der Anfrage
     * @param host der host auf dem der zu erreichende Dienst läuft
     * @param port der port auf dem der zu erreichende Dienst hört
     * @param objectName der Name des Objektes / Dienstes der kontaktiert werden soll
     * @param methodName die Methode beim Dienst aufgerufen werden soll
     * @param args die Argumente für die Methode
     */
    void call(int reqeustID, String host, int port, String objectName, String methodName, Object[] args);

    /**
     * Bearbeitet die Antwort einer Anfrage
     * @param requestID die ID der Anfrage
     * @param result die Antwort der Anfrage
     */
    void response(int requestID, Object result);
}

