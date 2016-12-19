package nameService;

import mware_lib.NameService;
import mware_lib.ObjectBroker;
import nameService._NameServiceProxy;

public class SimpleNameService extends NameService {
	ObjectBroker broker;
	_NameServiceProxy remoteNS;
	
	public SimpleNameService(ObjectBroker broker,String NSaddr) {
		this.broker=broker;
		remoteNS=new _NameServiceProxy(NSaddr);
		remoteNS.broker = broker;
	}
	
	public void rebind(Object servant, String name) throws Exception{
		broker.registerLocal(servant, name);
		remoteNS.rebind(broker.getHost(), broker.getPort(), name);
	}
	public String resolve(String name) throws Exception{
		return remoteNS.getService(name);
	}
}
