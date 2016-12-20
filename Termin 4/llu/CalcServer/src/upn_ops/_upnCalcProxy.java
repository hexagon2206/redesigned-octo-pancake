package upn_ops;

import mware_lib.SpezialObjectBroker;

import mware_lib.RefClass;

public class _upnCalcProxy extends _upnCalcImplBase {

	public String ref;
	public SpezialObjectBroker broker;

	public _upnCalcProxy(Object ref){
		this.ref = ((RefClass)ref).ref;
		this.broker = ((RefClass)ref).broker;
	}

	public int push(
		 double value
	) throws Exception {
		Object o = this.broker.syncCall(this.ref,"push",value);
		if(o instanceof Exception)throw ((Exception)o);
		return (int)o;
	}

	public double pop(
	) throws Exception {
		Object o = this.broker.syncCall(this.ref,"pop");
		if(o instanceof Exception)throw ((Exception)o);
		return (double)o;
	}

	public int add(
	) throws Exception {
		Object o = this.broker.syncCall(this.ref,"add");
		if(o instanceof Exception)throw ((Exception)o);
		return (int)o;
	}

	public int sub(
	) throws Exception {
		Object o = this.broker.syncCall(this.ref,"sub");
		if(o instanceof Exception)throw ((Exception)o);
		return (int)o;
	}

	public int mul(
	) throws Exception {
		Object o = this.broker.syncCall(this.ref,"mul");
		if(o instanceof Exception)throw ((Exception)o);
		return (int)o;
	}

	public int div(
	) throws Exception {
		Object o = this.broker.syncCall(this.ref,"div");
		if(o instanceof Exception)throw ((Exception)o);
		return (int)o;
	}

	public int pow(
	) throws Exception {
		Object o = this.broker.syncCall(this.ref,"pow");
		if(o instanceof Exception)throw ((Exception)o);
		return (int)o;
	}

	public int dup(
	) throws Exception {
		Object o = this.broker.syncCall(this.ref,"dup");
		if(o instanceof Exception)throw ((Exception)o);
		return (int)o;
	}

	public String getStr(
		 double a
	) throws Exception {
		Object o = this.broker.syncCall(this.ref,"getStr",a);
		if(o instanceof Exception)throw ((Exception)o);
		return (String)o;
	}

}
