package math_ops;

import mware_lib.ObjectBroker;

public class _CalculatorProxy extends _CalculatorImplBase {

	private String ref;
	private ObjectBroker broker;

	public _CalculatorProxy(String ref){
		this.ref = ref;
		this.broker = ObjectBroker.newest;
	}

	public double add(
		 double a
		,double b
	) throws Exception {
		Object o = this.broker.syncCall(this.ref,"add",a,b);
		if(o instanceof Exception)throw ((Exception)o);
		return (double)o;
	}

	public String getStr(
		 double a
	) throws Exception {
		Object o = this.broker.syncCall(this.ref,"getStr",a);
		if(o instanceof Exception)throw ((Exception)o);
		return (String)o;
	}

}
