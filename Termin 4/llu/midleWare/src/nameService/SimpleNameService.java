package nameService;

import mware_lib.NameService;
import mware_lib.ObjectBroker;
import mware_lib.RefClass;
import mware_lib.SpezialObjectBroker;
import mware_lib._NameServiceProxy;

public class SimpleNameService extends NameService {
	SpezialObjectBroker broker;
	_NameServiceProxy remoteNS;
	
	public SimpleNameService(SpezialObjectBroker broker,String NSaddr) {
		this.broker=broker;
		remoteNS=new _NameServiceProxy(new RefClass(NSaddr, broker));
	}
	
	public void rebind(Object servant, String name) throws Exception{
		broker.registerLocal(servant, name);
		remoteNS.rebind(broker.getHost(), broker.getPort(), name);
	}
	public Object resolve(String name) throws Exception{
		String ref = remoteNS.getService(name);
		return new RefClass(ref,this.broker);
	}
}
