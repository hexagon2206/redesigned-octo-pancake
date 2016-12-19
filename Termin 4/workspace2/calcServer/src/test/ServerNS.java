package test;

import java.io.IOException;
import java.net.InetAddress;

import math_ops.Calculator;
import mware_lib.NameService;
import mware_lib.ObjectBroker;

public class ServerNS {
	public static void main(String []args){
		try {
			InetAddress localAddres = InetAddress.getByName(args[0]);
			ObjectBroker broker = ObjectBroker.init(localAddres,args[1], 1237, false);
			NameService ns = broker.getNameService();
			ns.rebind(new Calculator(), "calc");
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (Exception e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}
}
