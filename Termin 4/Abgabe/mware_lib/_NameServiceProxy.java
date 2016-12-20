package mware_lib;

public class _NameServiceProxy extends _NameServiceImplBase {

	public String ref;
	public SpezialObjectBroker broker;

	public _NameServiceProxy(Object ref){
		this.ref = ((RefClass)ref).ref;
		this.broker = ((RefClass)ref).broker;
	}

	public int rebind(
		 String host
		,int port
		,String name
	) throws Exception {
		Object o = this.broker.syncCall(this.ref,"rebind",host,port,name);
		if(o instanceof Exception)throw ((Exception)o);
		return (int)o;
	}

	public String getService(
		 String name
	) throws Exception {
		Object o = this.broker.syncCall(this.ref,"getService",name);
		if(o instanceof Exception)throw ((Exception)o);
		return (String)o;
	}

}
