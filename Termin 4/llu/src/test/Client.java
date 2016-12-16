package test;

import java.io.IOException;

import mware_lib.ObjectBroker;

public class Client {
	public static void main(String []args){
		try {
			ObjectBroker broaker = ObjectBroker.init("127.0.0.1", 1236, false);
			
			System.out.println(broaker.syncCall("127.0.0.1:1237:calc", "add", 10,15));
			System.out.println(broaker.syncCall("127.0.0.1:1237:calc", "add", 5,10));
			System.out.println(broaker.syncCall("127.0.0.1:1237:calc", "add", 10,55));
			while(true){}
			
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}
}
