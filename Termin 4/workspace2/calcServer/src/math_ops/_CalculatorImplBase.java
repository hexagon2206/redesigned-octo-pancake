package math_ops;

public abstract class _CalculatorImplBase {

	public static _CalculatorImplBase narrowCast(String rawObjectRef) {
		return new _CalculatorProxy(rawObjectRef);
	}

	public abstract double add(
		 double a
		,double b
	) throws Exception ;

	public abstract String getStr(
		 double a
	) throws Exception ;

}
