package nameService;

import java.net.Inet4Address;
import java.util.HashMap;
import java.util.Map;

import nameService._NameServiceImplBase;

public class NameServiceImpl extends _NameServiceImplBase {

	Map<String, String> services = new HashMap<>();
	
	@Override
	public int rebind(String host, int port, String name) throws Exception {
		String addr = Inet4Address.getByName(host).getHostAddress()+":"+port+":"+name;
		services.put(name, addr);
		return 0;
	}

	@Override
	public String getService(String name) throws Exception {
		String s = services.get(name);
		System.out.println("answer  :"+s);	
		return s;
	}

}
