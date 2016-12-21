package math_ops;

public abstract class _CalculatorImplBase {

	public static _CalculatorImplBase narrowCast(Object rawObjectRef) {
		return new _CalculatorProxy(rawObjectRef);
	}

	public abstract double add(
		 double p0
		,double p1
	) throws Exception ;

	public abstract double sub(
		 double p0
		,double p1
	) throws Exception ;

}
