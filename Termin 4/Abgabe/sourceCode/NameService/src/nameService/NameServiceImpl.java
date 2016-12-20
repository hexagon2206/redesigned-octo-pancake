package nameService;

import java.net.Inet4Address;
import java.util.HashMap;
import java.util.Map;

import mware_lib._NameServiceImplBase;

public class NameServiceImpl extends _NameServiceImplBase {

	Map<String, String> services = new HashMap<>();
	
	@Override
	public int rebind(String host, int port, String name) throws Exception {
		String addr = Inet4Address.getByName(host).getHostAddress()+":"+port+":"+name;
		synchronized (services) {
			services.put(name, addr);	
		}
		return 0;
	}

	@Override
	public String getService(String name) throws Exception {
		String s;
		synchronized (services) {
			s = services.get(name);
		}
		
		if(s==null){
			System.out.println(name + " can not be resolved");
			throw new RuntimeException("name cant be resolved");
		}else{
			System.out.println(name +" -> "+s);	
		}
		return s;
	}

}
