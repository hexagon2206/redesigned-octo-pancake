package mware_lib;

import java.io.IOException;

public abstract class ObjectBroker {
	// Das hier zur ckgelieferte Objekt soll der zentrale Einstiegspunkt 
	// der Middleware aus Applikationssicht sein.
	// Parameter: Host und Port, bei dem die Dienste (hier: Namensdienst)
	//            kontaktiert werden sollen. Mit debug sollen Test 
	//            ausgaben der Middleware ein  oder ausgeschaltet werden
	//            kennen. 
	
	public static ObjectBroker init(String serviceHost, int listenPort, boolean debug) throws IOException{
		return SpezialObjectBroker.init(serviceHost,listenPort,debug);
	}
	

	
	// Liefert den Namensdienst (Stellvetreterobjekt).	
	
	public abstract NameService getNameService();
	
	public abstract void shutDown();
		
}
