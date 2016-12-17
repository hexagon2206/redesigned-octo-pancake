package nameService;

import mware_lib.ObjectBroker;

public class _NameServiceProxy extends _NameServiceImplBase {

	public String ref;
	public ObjectBroker broker;

	public _NameServiceProxy(String ref){
		this.ref = ref;
		this.broker = ObjectBroker.newest;
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
