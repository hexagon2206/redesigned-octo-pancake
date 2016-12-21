package mware_lib;

public abstract class _NameServiceImplBase {

	public static _NameServiceImplBase narrowCast(Object rawObjectRef) {
		return new _NameServiceProxy(rawObjectRef);
	}

	public abstract int rebind(
		 String host
		,int port
		,String name
	) throws Exception ;

	public abstract String getService(
		 String name
	) throws Exception ;

}
