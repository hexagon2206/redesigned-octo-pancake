package nameService;

import java.io.IOException;
import java.net.InetAddress;

import mware_lib.ObjectBroker;

public class Main {
	
	private static void usage(){
		System.out.println("Not used Corecley:");
		System.out.println("\tprogrammName port ServiceName localInterfaceArress");
	}
	public static void main(String []args){
		if(args.length!=3){
			usage();
			return;
		}
		int port;
		String name;
		
		try{
			port = Integer.parseInt(args[0]);
			name = args[1];
		}catch(Exception e){
			usage();
			return;
		}
		try {
			InetAddress localAddres = InetAddress.getByName(args[2]);
			ObjectBroker broker = ObjectBroker.init(localAddres,port, false);
			broker.registerLocal(new NameServiceImpl(), name);
		} catch (IOException e) {
			e.printStackTrace();
		}
	}
}
