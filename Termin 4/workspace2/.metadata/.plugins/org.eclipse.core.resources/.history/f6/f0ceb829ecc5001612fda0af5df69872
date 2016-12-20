package test;

import java.io.IOException;

import math_ops._CalculatorImplBase;
import mware_lib.NameService;
import mware_lib.ObjectBroker;

public class ClientNS {
	public static void main(String []args){
		try {
			ObjectBroker broker = ObjectBroker.init("127.0.0.1", 1237, false);
			NameService ns = broker.getNameService();
			String calcAddr = (String)ns.resolve("calc");
			_CalculatorImplBase calc = _CalculatorImplBase.narrowCast(calcAddr);
			
			try {
				System.out.println(calc.add(5, 11));
				System.out.println(calc.getStr(calc.add(-5, 11)));
			} catch (Exception e) {
				e.printStackTrace();
			}
			broker.shutDown();			
		} catch (IOException e ) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (Exception e1) {
			// TODO Auto-generated catch block
			e1.printStackTrace();
		} 
	}
}
