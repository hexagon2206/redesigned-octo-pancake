package test;

import java.io.IOException;
import java.net.InetAddress;

import math_ops.Calculator;
import mware_lib.NameService;
import mware_lib.ObjectBroker;
import mware_lib.SpezialObjectBroker;
import upn_ops.UpnCalcImpl;

public class ServerNS {
	private static void usage(){
		System.out.println("first parameter is the local interface addres, secend the remote addres of NS and third the remote port");
	}
	public static void main(String []args){
		if(args.length!=3){
			usage();
			return;
		}
		String localInterface = args[0];
		String removeAddress  = args[1];
		int port = Integer.parseInt(args[2]);
		try {
			InetAddress myAddress = InetAddress.getByName(localInterface);
			
			SpezialObjectBroker broker = SpezialObjectBroker.init(myAddress,removeAddress, port, false);
			NameService ns = broker.getNameService();
			ns.rebind(new Calculator(), "calc");
			ns.rebind(new UpnCalcImpl(), "upn");
			System.out.println("Calc Server up and Running at "+broker.getHost()+":"+broker.getPort()+". . .");
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (Exception e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}
}
