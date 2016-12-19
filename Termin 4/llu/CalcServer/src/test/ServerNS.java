package test;

import java.io.IOException;

import math_ops.Calculator;
import mware_lib.NameService;
import mware_lib.ObjectBroker;

public class ServerNS {
	public static void main(String []args){
		try {
			ObjectBroker broker = ObjectBroker.init("127.0.0.1", 1237, false);
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
