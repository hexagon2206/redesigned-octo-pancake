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
		 double p0
		,double p1
	) throws Exception {
		Object o = this.broker.syncCall(this.ref,"add",p0,p1);
		if(o instanceof Exception)throw ((Exception)o);
		return (double)o;
	}

	public double sub(
		 double p0
		,double p1
	) throws Exception {
		Object o = this.broker.syncCall(this.ref,"sub",p0,p1);
		if(o instanceof Exception)throw ((Exception)o);
		return (double)o;
	}

}
