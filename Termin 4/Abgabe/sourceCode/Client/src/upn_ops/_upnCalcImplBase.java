package upn_ops;

public abstract class _upnCalcImplBase {

	public static _upnCalcImplBase narrowCast(Object rawObjectRef) {
		return new _upnCalcProxy(rawObjectRef);
	}

	public abstract int push(
		 double value
	) throws Exception ;

	public abstract double pop(
	) throws Exception ;

	public abstract int add(
	) throws Exception ;

	public abstract int sub(
	) throws Exception ;

	public abstract int mul(
	) throws Exception ;

	public abstract int div(
	) throws Exception ;

	public abstract int pow(
	) throws Exception ;

	public abstract int dup(
	) throws Exception ;

	public abstract String getStr(
		 double a
	) throws Exception ;

}
