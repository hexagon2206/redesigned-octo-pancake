package test;

import java.io.IOException;
import java.net.InetAddress;

import math_ops.Calculator;
import mware_lib.NameService;
import mware_lib.ObjectBroker;
import mware_lib.SpezialObjectBroker;
import upn_ops.UpnCalcImpl;

public class ServerSimple {
	private static void usage(){
		System.out.println("first parameter is the remote addres of NS and second the remote port");
	}
	public static void main(String []args){
		if(args.length!=2){
			usage();
			return;
		}
		String removeAddress  = args[0];
		int port = Integer.parseInt(args[1]);
		try {
			
			ObjectBroker broker = ObjectBroker.init(removeAddress, port, false);
			NameService ns = broker.getNameService();
			ns.rebind(new Calculator(), "calc");
			ns.rebind(new UpnCalcImpl(), "upn");
			System.out.println("Calc Server up and Running . . .");
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (Exception e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}
}
