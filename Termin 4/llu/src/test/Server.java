package test;

import java.io.IOException;

import mware_lib.ObjectBroker;

public class Server {
	public static void main(String []args){
		try {
			ObjectBroker broker = ObjectBroker.init(1237, false);
			broker.registerLocal(new hugo(), "calc");
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