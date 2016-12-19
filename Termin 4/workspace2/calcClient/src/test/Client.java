package test;

import java.io.IOException;
import java.net.InetAddress;

import math_ops._CalculatorImplBase;
import math_ops._CalculatorProxy;
import mware_lib.ObjectBroker;

public class Client {
	public static void main(String []args){
		try {
			InetAddress localAddres = InetAddress.getByName(args[0]);
			ObjectBroker broker = ObjectBroker.init(localAddres,args[1], 1237, false);
			
			_CalculatorImplBase calc = new _CalculatorProxy("127.0.0.1:1237:calc");
			try {
				System.out.println(calc.add(5, 11));
			} catch (Exception e) {
				e.printStackTrace();
			}
			
			
			while(true){}
			
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}
}
