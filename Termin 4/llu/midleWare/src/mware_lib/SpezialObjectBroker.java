package mware_lib;

import java.io.IOException;
import java.lang.reflect.InvocationTargetException;
import java.net.Inet4Address;
import java.net.InetAddress;
import java.net.SocketAddress;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.ThreadPoolExecutor;

import mware_lib.exceptions.NoResponseException;
import nameService.SimpleNameService;

public class SpezialObjectBroker extends ObjectBroker{
	
	public int timeout = 10000;
	Integer RequestID = 0;
	int getRequestID(){
		synchronized (RequestID) {
			return RequestID++;
		}
	}
	
	ExecutorService executor;
	
	
	public static SpezialObjectBroker newest=null;
	
	Map<Integer, Object> responses;
	
	Map<String, Object> registeredObjects;
	
	Kommunikationsmodul kmon;
	Thread kmonThread;
	
	NameService ns;
	
	private SpezialObjectBroker(InetAddress localAddres,int myPort) throws IOException{
				responses = new HashMap<>();
		registeredObjects = new HashMap<>();
		executor =  Executors.newCachedThreadPool();
		
		kmon=new Kommunikationsmodul(myPort, this,localAddres);
		kmonThread = new Thread(kmon);
		kmonThread.start();
		SpezialObjectBroker.newest=this;
	};
	
	private SpezialObjectBroker(InetAddress localAddres,String server,int port,int myPort) throws IOException{
		this(localAddres,myPort);
		InetAddress addr = Inet4Address.getByName(server);
		ns=new SimpleNameService(this,addr.getHostAddress()+":"+port+":ns");		
	}
	//ï¿½Dasï¿½hierï¿½zurï¿½ckgelieferteï¿½Objektï¿½sollï¿½derï¿½zentraleï¿½Einstiegspunktï¿½
	//ï¿½derï¿½Middlewareï¿½ausï¿½Applikationssichtï¿½sein.
	//ï¿½Parameter:ï¿½Hostï¿½undï¿½Port,ï¿½beiï¿½demï¿½dieï¿½Diensteï¿½(hier:ï¿½Namensdienst)
	//ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½kontaktiertï¿½werdenï¿½sollen.ï¿½Mitï¿½debugï¿½sollenï¿½Testï¿½
	//ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ausgabenï¿½derï¿½Middlewareï¿½einï¿½ï¿½oderï¿½ausgeschaltetï¿½werden
	//ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½kï¿½nnen.ï¿½
	
	public static SpezialObjectBroker init(InetAddress localAddres,String serviceHost, int listenPort, int myPort,boolean debug) throws IOException{
		return new SpezialObjectBroker(localAddres,serviceHost, listenPort,myPort);
	}
	
	/**
	 * Die gewünschte schnittstelle
	 */
	public static SpezialObjectBroker init(String serviceHost, int listenPort, boolean debug) throws IOException{
		InetAddress addr = InetAddress.getLocalHost();
		return init(addr,serviceHost,listenPort, debug);
	}
	
	public static SpezialObjectBroker init(InetAddress localAddres,String serviceHost, int listenPort, boolean debug) throws IOException{
			return init(localAddres,serviceHost,listenPort,0,debug);
	}	
	public static SpezialObjectBroker init(InetAddress localAddres,int listenPort, boolean debug) throws IOException{
		return new SpezialObjectBroker(localAddres,listenPort);
	}

	
	//ï¿½Liefertï¿½denï¿½Namensdienstï¿½(Stellvetreterobjekt).	
	
	public NameService getNameService(){
		
		return ns;
	}
	
	//ï¿½Beendetï¿½dieï¿½Benutzungï¿½derï¿½Middlewareï¿½inï¿½dieserï¿½Anwendung.
	@SuppressWarnings("deprecation")
	public void shutDown(){
		executor.shutdown();
		kmonThread.stop();
	}
	
	
	public Object syncCall(String referenz, String Methode, Object... args) throws NoResponseException{
		int key = asyncCall(referenz,Methode,args);
		Object ret;
		long waitTill = System.currentTimeMillis() + timeout;
		synchronized (responses) {
			while(null== (ret = getResponse(key))){
				try {
					long t = (waitTill-System.currentTimeMillis());
					if(t<=0){
						throw new NoResponseException();
					}
					responses.wait(t);
				} catch (InterruptedException e) {}
			}
		}
		return ret;
	}
	
	public void response(int RequestID,Object response){
		synchronized (responses) {
			System.out.println("Recived Resoinse For " + RequestID);
			responses.put(RequestID, response);
			responses.notifyAll();
		}
	}
	
	public int asyncCall(String referenz, String Methode, Object... args){
		int key = getRequestID();
		String[] ref = referenz.split(":");
		System.out.println("Call For " + referenz + " ID : " +key);
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
	
	private class CallTask implements Runnable{
		
		SocketAddress socketAddress;
		int reqID;
		String name;
		String methode;
		Object[] args;
		Kommunikationsmodul kmon;
		
		public void run() {
			System.out.println("Call to :"+name+"."+methode+"("+args+")"+reqID);

			
			Object r;
			try {
				Object o = registeredObjects.get(name);
				Class<?>[] argTypes = new Class<?>[args.length];
				for(int i = 0;i<argTypes.length;i++){
					argTypes[i]=toClass(args[i]);
				}
				r = o.getClass().getMethod(methode, argTypes).invoke(o, args);
			}catch (InvocationTargetException e) {
				r=e.getCause();
			}catch (Exception e) {
				r=e;
			}
			try {
				synchronized (kmon) {
					kmon.response(socketAddress,reqID, r);					
				}
			} catch (IOException e) {
				e.printStackTrace();
			}
		}
	}
	void call(SocketAddress socketAddress, int reqID,String name,String methode,Object[] args){
		
		CallTask ct = new CallTask();
		ct.args=args;
		ct.kmon = this.kmon;
		ct.methode=methode;
		ct.name=name;
		ct.reqID=reqID;
		ct.socketAddress=socketAddress;
		
		executor.execute(ct);
		
	
		
	}
	/**
	 * @return the address of the local socket
	 */
	public String getHost() {
		return kmon.getHost();
	}

	/**
	 * @return the port of the local socket
	 */
	public int getPort() {
		return kmon.getPort();
	}
	
}
