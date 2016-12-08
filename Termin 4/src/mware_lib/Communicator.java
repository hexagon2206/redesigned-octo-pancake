package mware_lib;

import java.net.InetAddress;

/**
 * Übernimmt für den Client und den Server die Kommunikation zur jeweiels anderen Partei
 *
 * Anwendungsfälle:
 * 1. Client stellt Anfrage
 * 2. Server benatwortet Anfrage
 * 3. Fehler wird festgestellt und an den Verursacher übertragen
 * TODO:
 * - Wie soll die Nachricht im Detail aussen? (Datentyp etc.)
 */
public interface Communicator {

    /**
     * Sendet eine Nachricht an den übergeben Empfänger
     * @param reciever die IP - Addresse des Empfängers
     * @return true wenn erfolgreich übermittelt; ansonsten false
     */
    boolean sendMessage(InetAddress reciever);

    /**
     * Initalisiert den Listener auf dem das Kommunikationsmodul hören soll, um Nachrichten zu empfangen
     * @param port der Port auf dem gelauscht werden soll
     * @return gibt true zurück, wenn der Listener erfolgreich gestartet werden konnte; false wenn nicht
     */
    boolean listenToPort(int port);
}
