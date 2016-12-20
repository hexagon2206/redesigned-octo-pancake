package nameService;

import java.io.IOException;
import java.net.InetAddress;

import mware_lib.ObjectBroker;
import mware_lib.SpezialObjectBroker;

public class Main {
	
	private static void usage(){
		System.out.println("Not used Corecley:");
		System.out.println("\tParameter must be :  localAddress port");
	}
	public static void main(String []args){
		if(args.length!=2){
			usage();
			return;
		}
		int port;
		String localAddress;
		
		try{
			port = Integer.parseInt(args[1]);
			localAddress = args[0];
		}catch(Exception e){
			usage();
			return;
		}
		
		try {
			InetAddress myAddress = InetAddress.getByName(localAddress);
			SpezialObjectBroker broker = SpezialObjectBroker.init(myAddress,port, false);
			broker.registerLocal(new NameServiceImpl(), "ns");
			System.out.println("Nameservice Up and running at "+ broker.getHost() + ":" + broker.getPort());
		} catch (IOException e) {
			e.printStackTrace();
		}
	}
}
