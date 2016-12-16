package mware_lib;

import java.io.ByteArrayOutputStream;
import java.io.DataOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.lang.reflect.Constructor;
import java.lang.reflect.InvocationTargetException;
import java.net.Inet4Address;
import java.net.InetAddress;
import java.net.InetSocketAddress;
import java.net.ServerSocket;
import java.net.Socket;
import java.net.SocketAddress;
import java.net.SocketTimeoutException;
import java.net.UnknownHostException;
import java.nio.ByteBuffer;
import java.text.ParseException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;

import org.xml.sax.InputSource;


public class Kommunikationsmodul  implements Runnable  {
	
	ServerSocket ss;
	
	private class SocketListEntrie{
		SocketListEntrie(Socket s) throws IOException{
			this.s = s;
			this.baos = new ByteArrayOutputStream();
			this.os = s.getOutputStream();
			this.is = s.getInputStream();
		}
		Socket s;
		ByteArrayOutputStream baos;
		OutputStream os;
		InputStream is;
	}
	
	
	Map<SocketAddress,SocketListEntrie> sockets;
	
	Map<Integer, SocketAddress> openRequest;
	
	ObjectBroker broaker;
	
	public Kommunikationsmodul(int port,ObjectBroker broaker) throws IOException{
		ss= new ServerSocket(port);
		ss.setSoTimeout(1);
		sockets=new HashMap<>();
		openRequest = new HashMap<>();
		this.broaker = broaker;
	}
	
	
	public void call(int requestID,String host,int port,String objName,String methode,Object... args) throws IOException{
		Request re = new Request();
		re.requestID = requestID;
		re.obj=objName;
		re.methode=methode;
		re.args=args;
		
		byte[] data = Decoder.request2Bytes(re);
		InetAddress inet = InetAddress.getByName(host);
		SocketAddress sockAddr = new InetSocketAddress(inet,port);
		SocketListEntrie s = sockets.get(sockAddr);
		
		
		if(s==null || s.s.isClosed()){
			System.out.println("opening new Route");
			s=new SocketListEntrie(new Socket(inet,port));
			sockets.put(sockAddr, s);
		}
		
		synchronized (s) {
			s.os.write(data);
			s.os.flush();
		}
	}
	public void response(int RequestID,Object returnValue) throws IOException{
		SocketAddress addr;
		synchronized (openRequest) {
			addr = openRequest.get(RequestID);
			if(null!=addr){
				openRequest.remove(RequestID);
			}
		}
		if(null==addr){
			//TODO neue verbindung öfnen
		}else{
			Response rs=new Response();
			rs.requestID=RequestID;
			rs.value = returnValue;
	
			byte[]data = Decoder.response2Bytes(rs);
			SocketListEntrie s = sockets.get(addr);
			synchronized (s) {
				s.os.write(data);
				s.os.flush();
			}
		}
	}
	
	public void run(){
		try {
			while(true){
				try{
					Socket s = ss.accept();
					System.out.println("connection from :"+s.getRemoteSocketAddress());
					SocketListEntrie os = sockets.get(s.getRemoteSocketAddress());
					if(os==null || os.s.isClosed()){
						sockets.put(s.getRemoteSocketAddress(), new SocketListEntrie(s));
						System.out.println("new Route to Target");
					}
				}catch(SocketTimeoutException e){}
				//TODO eingehende verbindungen auf daten prüfen
				for(Map.Entry<SocketAddress,SocketListEntrie> e:sockets.entrySet()){
					SocketListEntrie sle = e.getValue();
					int readable = sle.is.available();
					if(0!=readable){
						byte[] data = new byte[readable];
						readable = sle.is.read(data);
						if(readable>0){
							sle.baos.write(data, 0, readable);
						}
						Message m;
						while(null!=(m=Decoder.decode(sle.baos))){
							if(m instanceof Request){
								synchronized (openRequest) {
									openRequest.put(((Request)m).requestID, e.getKey());
								}
								broaker.call(((Request)m).requestID, ((Request)m).obj, ((Request)m).methode, ((Request)m).args);
							}else if(m instanceof Response){
								broaker.response(((Response)m).requestID, ((Response)m).value);
							}
						}
					}
				}
			}
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (InstantiationException e1) {
			// TODO Auto-generated catch block
			e1.printStackTrace();
		} catch (IllegalAccessException e1) {
			// TODO Auto-generated catch block
			e1.printStackTrace();
		} catch (IllegalArgumentException e1) {
			// TODO Auto-generated catch block
			e1.printStackTrace();
		} catch (InvocationTargetException e1) {
			// TODO Auto-generated catch block
			e1.printStackTrace();
		} catch (NoSuchMethodException e1) {
			// TODO Auto-generated catch block
			e1.printStackTrace();
		} catch (SecurityException e1) {
			// TODO Auto-generated catch block
			e1.printStackTrace();
		} catch (ClassNotFoundException e1) {
			// TODO Auto-generated catch block
			e1.printStackTrace();
		}
	}
	
}
