package mware_lib;

import mware_lib.interfaces.ObjectBrokerInterface;
import java.util.HashMap;

public class ObjectBroker implements ObjectBrokerInterface {

    // Enthält die registrierten Objekte mit dazugehörigen Namen
    private HashMap<String, Object> _registeredObjects = new HashMap<>();
    // Hält die Antworten der Anfragen vor
    private HashMap<Integer, Object> _responses = new HashMap<>();
    private boolean _keepRunning = true;

    /**
     * Liefert den Namensdienst
     *
     * @return das Namensdienstobjekt
     */
    @Override
    public NameService getNameservice() {
        return null;
    }

    /**
     * Fährt das System herunter
     */
    @Override
    public void shutDown() {
        _keepRunning = false;
    }

    /**
     * Führt einen synchronen Aufruf durch
     * @param reference die Referenz des Objektes, an das der Aufruf geht
     * @param methodName der Name der Methode, die aufgerufn werden soll
     * @param args die Argumente für die Methode
     * @return das Ergebnis des Aufrufes; eine Exception falls ein Fehler aufgetreten ist
     */
    private Object syncCall(String reference, String methodName, Object[] args){
        return null;
    }

    /**
     * Wird vom Kommunikationsmodul aufgerufen, um eine Antwort an den ObjectBroker zu übergeben
     * @param requestID die ID der Anfrage
     * @param response die Antwort der Anfrage
     */
    private void response(int requestID, Object response){
        if (!_responses.containsKey(requestID)) {
            _responses.put(requestID, response);
        }else{
            System.out.println("RequestID schon vorhanden");
        }
    }

    /**
     * Führt einen asynchronen Aufruf durch
     * @param reference die Referenz des Objektes, an das der Aufruf geht
     * @param methodName der Name der Methode, die aufgerufn werden soll
     * @param args die Argumente für die Methode
     * @return
     */
    private int asyncCall(String reference, String methodName, Object[] args){
        return 0;
    }

    /**
     * Liefert zu einer RequestID die dazugehörige Antwort zurück
     * @param requestID die ID für die eine Antwort gesucht wird
     * @return den Response wenn vorhanden; ansonsten null
     */
    private Object getResponse(int requestID){
        return null;
    }

    private void registerLocal(Stellvertreter sv, String name){

    }

}
