package math_ops;

import javax.management.RuntimeErrorException;

public class Calculator extends _CalculatorImplBase {

	@Override
	public double add(double a, double b) throws Exception {
		return a+b;
	}

	@Override
	public String getStr(double a) throws Exception {
		throw new RuntimeException(Double.toString(a));
	}

}
