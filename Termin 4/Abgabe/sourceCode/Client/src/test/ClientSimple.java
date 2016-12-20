package test;

import java.io.IOException;
import java.net.InetAddress;

import math_ops._CalculatorImplBase;
import mware_lib.NameService;
import mware_lib.ObjectBroker;
import mware_lib.SpezialObjectBroker;
import upn_ops._upnCalcImplBase;

public class ClientSimple {	
	
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

		ObjectBroker broker=null;
		try {
			
			broker = ObjectBroker.init(removeAddress, port, false);
			NameService ns = broker.getNameService();
			
			_CalculatorImplBase calc = _CalculatorImplBase.narrowCast(ns.resolve("calc"));
			_upnCalcImplBase upn = _upnCalcImplBase.narrowCast(ns.resolve("upn"));
			try {
				
				System.out.println(calc.add(5, 11));
				System.out.println(calc.getStr(calc.add(-5, 11)));
				System.out.println("UPN Test _____________");
				upn.push(15.0);
				upn.push(5.0);
				upn.add();
				System.out.println(upn.getStr(upn.pop()));
				
				
				
				
			} catch (Exception e) {
				e.printStackTrace();
			}

			
			
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
