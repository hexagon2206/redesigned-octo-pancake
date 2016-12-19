package test;

import java.io.IOException;
import java.net.InetAddress;

import math_ops.Calculator;
import mware_lib.ObjectBroker;

public class Server {
	public static void main(String []args){
		try {
			InetAddress localAddres = InetAddress.getByName(args[0]);
			ObjectBroker broker = ObjectBroker.init(localAddres,args[1], 1237, false);
			broker.registerLocal(new Calculator(), "calc");
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}
}

class hugo{
	public Integer add(Integer a,Integer b){
			return a+b;
	}
} 