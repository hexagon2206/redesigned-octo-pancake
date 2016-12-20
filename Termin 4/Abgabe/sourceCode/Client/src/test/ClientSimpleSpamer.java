package test;

import java.io.IOException;
import java.net.InetAddress;
import java.util.concurrent.ThreadLocalRandom;

import math_ops._CalculatorImplBase;
import mware_lib.NameService;
import mware_lib.ObjectBroker;
import mware_lib.SpezialObjectBroker;
import upn_ops._upnCalcImplBase;

public class ClientSimpleSpamer {	
	
	private static void usage(){
		System.out.println("first parameter is the remote addres of NS and second the remote port");
	}
	private static class testRunner implements Runnable{
		ObjectBroker broker;
		public testRunner(){}
		@Override
		public void run() {
			try {
				NameService ns = broker.getNameService();
				_CalculatorImplBase obj = _CalculatorImplBase.narrowCast(ns.resolve("calc"));
				
				for(int i = 0;i!=100;i++){
					if((i+i+1)!=obj.add(i, i+1)) System.out.println("wrong response");
				}
				System.out.println("Alles OK");
			} catch (Exception e) {
				e.printStackTrace();
			}
			
		}
		
	}
	
	public static void main(String []args){
		if(args.length!=2){
			usage();
			return;
		}
		String removeAddress  = args[0];
		int port = Integer.parseInt(args[1]);

		ObjectBroker broker=null;
		try {
			
			broker = ObjectBroker.init(removeAddress, port, false);
			int X = 10;
			Thread[] ts = new Thread[X];
			for(int i = 0;i!=ts.length;i++){
				testRunner t = new testRunner();
				t.broker=broker;
				ts[i] = new Thread(t);
				ts[i].start();
			}
			for(Thread t:ts){
				t.join();
			}
			System.out.println("Alle Threads Terminiert");
			
		} catch (IOException e ) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (Exception e1) {
			// TODO Auto-generated catch block
			e1.printStackTrace();
		}finally {
			if(null!=broker)broker.shutDown();
		}
	}
}
