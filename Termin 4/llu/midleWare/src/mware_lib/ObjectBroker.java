package mware_lib;

import java.io.IOException;
import java.net.Inet4Address;
import java.net.InetAddress;
import java.net.SocketAddress;
import java.util.HashMap;
import java.util.Map;

import nameService.SimpleNameService;

public class ObjectBroker {
	
	Integer RequestID = 0;
	int getRequestID(){
		synchronized (RequestID) {
			return RequestID++;
		}
	}
	public static ObjectBroker newest=null;
	
	Map<Integer, Object> responses;
	
	Map<String, Object> registeredObjects;
	
	Kommunikationsmodul kmon;
	Thread kmonThread;
	
	NameService ns;
	
	private ObjectBroker(int myPort) throws IOException{
				responses = new HashMap<>();
		registeredObjects = new HashMap<>();
		
		kmon=new Kommunikationsmodul(myPort, this);
		kmonThread = new Thread(kmon);
		kmonThread.start();
		ObjectBroker.newest=this;
	};
	
	private ObjectBroker(String server,int port,int myPort) throws IOException{
		this(myPort);
		InetAddress addr = Inet4Address.getByName(server);
		ns=new SimpleNameService(this,addr.getHostAddress()+":"+port+":ns");		
	}
	//�Das�hier�zur�ckgelieferte�Objekt�soll�der�zentrale�Einstiegspunkt�
	//�der�Middleware�aus�Applikationssicht�sein.
	//�Parameter:�Host�und�Port,�bei�dem�die�Dienste�(hier:�Namensdienst)
	//������������kontaktiert�werden�sollen.�Mit�debug�sollen�Test�
	//������������ausgaben�der�Middleware�ein��oder�ausgeschaltet�werden
	//������������k�nnen.�
	
	public static ObjectBroker init(String serviceHost, int listenPort, int myPort,boolean debug) throws IOException{
		return new ObjectBroker(serviceHost, listenPort,myPort);
	}
	public static ObjectBroker init(String serviceHost, int listenPort, boolean debug) throws IOException{
		return init(serviceHost,listenPort,0,debug);
	}	
	public static ObjectBroker init(int listenPort, boolean debug) throws IOException{
		return new ObjectBroker(listenPort);
	}

	
	//�Liefert�den�Namensdienst�(Stellvetreterobjekt).	
	
	public NameService getNameService(){
		
		return ns;
	}
	
	//�Beendet�die�Benutzung�der�Middleware�in�dieser�Anwendung.
	@SuppressWarnings("deprecation")
	public void shutDown(){
		kmonThread.stop();
	}
	
	
	public Object syncCall(String referenz, String Methode, Object... args){
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
	
	public int asyncCall(String referenz, String Methode, Object... args){
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
	
	Class<?> toClass(Object o){
		if(o.getClass()==Integer.class){
			return int.class;
		}else if(o.getClass()==Double.class){
			return double.class;
		}
		
		
		return o.getClass();
	}
	
	void call(SocketAddress socketAddress, int reqID,String name,String methode,Object[] args) throws IOException{
	
		System.out.println("Call to :"+name+"."+methode+"("+args+")");

		Object r;
		try {
			Object o = registeredObjects.get(name);
			Class<?>[] argTypes = new Class<?>[args.length];
			for(int i = 0;i<argTypes.length;i++){
				argTypes[i]=toClass(args[i]);
			}
			r = o.getClass().getMethod(methode, argTypes).invoke(o, args);
		} catch (Exception e) {
			r=e;
		}
		kmon.response(socketAddress,reqID, r);
	}
	public String getHost() {
		return kmon.getHost();
	}
	public int getPort() {
		return kmon.getPort();
	}
	
}
