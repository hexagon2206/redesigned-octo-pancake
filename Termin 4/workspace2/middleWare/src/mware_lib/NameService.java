package mware_lib;

public abstract class NameService {
	public abstract void rebind(Object servant, String name) throws Exception;
	public abstract Object resolve(String name) throws Exception;
}
