package mware_lib;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

public class ObjectBroker {
	
	Integer RequestID = 0;
	int getRequestID(){
		synchronized (RequestID) {
			return RequestID++;
		}
	}
	
	Map<Integer, Object> responses;
	
	Map<String, Object> registeredObjects;
	
	Kommunikationsmodul kmon;
	Thread kmonThread;
	
	private ObjectBroker(int myPort) throws IOException{
				responses = new HashMap<>();
		registeredObjects = new HashMap<>();
		
		kmon=new Kommunikationsmodul(myPort, this);
		kmonThread = new Thread(kmon);
		kmonThread.start();
	
	}
	private ObjectBroker(String Server,int port,int myPort) throws IOException{
		this(myPort);
		
	}
	// Das hier zurückgelieferte Objekt soll der zentrale Einstiegspunkt 
	// der Middleware aus Applikationssicht sein.
	// Parameter: Host und Port, bei dem die Dienste (hier: Namensdienst)
	//            kontaktiert werden sollen. Mit debug sollen Test­
	//            ausgaben der Middleware ein­ oder ausgeschaltet werden
	//            können. 
	
	public static ObjectBroker init(String serviceHost, int listenPort, int myPort,boolean debug) throws IOException{
		return new ObjectBroker(serviceHost, listenPort,myPort);
	}
	public static ObjectBroker init(String serviceHost, int listenPort, boolean debug) throws IOException{
		return init(serviceHost,listenPort,0,debug);
	}	
	public static ObjectBroker init(int listenPort, boolean debug) throws IOException{
		return new ObjectBroker(listenPort);
	}

	
	// Liefert den Namensdienst (Stellvetreterobjekt).	
	
	public NameService getNameService(){
		
		return null;
	}
	
	// Beendet die Benutzung der Middleware in dieser Anwendung.
	public void shutDown(){
		kmonThread.stop();
	}
	
	
	public Object syncCall(String referenz, String Methode, Object... args) throws IOException{
		int key = asyncCall(referenz,Methode,args);
		Object ret;
		synchronized (responses) {
			while(null== (ret = getResponse(key))){
				try {
					responses.wait();
				} catch (InterruptedException e) {}
			}
		}
		return ret;
	}
	
	public void response(int RequestID,Object response){
		synchronized (responses) {
			responses.put(RequestID, response);
			responses.notifyAll();
		}
	}
	
	public int asyncCall(String referenz, String Methode, Object... args) throws IOException {
		int key = getRequestID();
		String[] ref = referenz.split(":");

		try {
			kmon.call(key, ref[0], Integer.parseInt(ref[1]), ref[2], Methode, args);
		} catch (NumberFormatException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		
		return key;
	}
	
	public Object getResponse(int RequestID){
		synchronized (responses) {
			Object r = responses.get(RequestID);
			if(null!=r){
				responses.remove(RequestID);
			}
			return r;
		}
	}
	
	public void registerLocal(Object sv,String Name){
		synchronized (registeredObjects) {
			registeredObjects.put(Name, sv);	
		}
	}
	
	void call(int reqID,String name,String methode,Object[] args) throws IOException{
	
		System.out.println("Call to :"+name+"."+methode+"("+args+")");

		Object r;
		try {
			Object o = registeredObjects.get(name);
			Class<?>[] argTypes = new Class<?>[args.length];
			for(int i = 0;i<argTypes.length;i++){
				argTypes[i]=args[i].getClass();
			}
			r = o.getClass().getMethod(methode, argTypes).invoke(o, args);
		} catch (Exception e) {
			r=e;
		}
		kmon.response(reqID, r);
	}
	
}
