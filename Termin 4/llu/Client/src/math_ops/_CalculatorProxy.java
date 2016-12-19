package math_ops;

import mware_lib.SpezialObjectBroker;

import mware_lib.RefClass;

public class _CalculatorProxy extends _CalculatorImplBase {

	public String ref;
	public SpezialObjectBroker broker;

	public _CalculatorProxy(Object ref){
		this.ref = ((RefClass)ref).ref;
		this.broker = ((RefClass)ref).broker;
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
