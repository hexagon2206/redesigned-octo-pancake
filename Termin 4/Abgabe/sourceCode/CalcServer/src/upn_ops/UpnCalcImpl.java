package upn_ops;

import java.util.Stack;

public class UpnCalcImpl extends _upnCalcImplBase {
	Stack<Double> stack = new Stack<>();
	
	@Override
	public int push(double value) throws Exception {
		synchronized (stack) {
			stack.push(value);	
		}
		return 0;
	}

	@Override
	public double pop() throws Exception {
		synchronized (stack) {
			return stack.pop();	
		}
	}

	@Override
	public int add() throws Exception {
		synchronized (stack) {
			double 	 a = stack.pop()
					,b = stack.pop();	
			stack.push(a+b);
		}
		return 0;
	}

	@Override
	public String getStr(double a) throws Exception {
		return Double.toString(a);
	}

	@Override
	public int sub() throws Exception {
		synchronized (stack) {
			double 	 a = stack.pop()
					,b = stack.pop();	
			stack.push(b-a);
		}
		return 0;
	}

	@Override
	public int mul() throws Exception {
		synchronized (stack) {
			double 	 a = stack.pop()
					,b = stack.pop();	
			stack.push(a*b);
		}
		return 0;
	}

	@Override
	public int div() throws Exception {
		synchronized (stack) {
			double 	 a = stack.pop()
					,b = stack.pop();	
			stack.push(b/a);
		}
		return 0;
	}

	@Override
	public int pow() throws Exception {
		synchronized (stack) {
			double 	 a = stack.pop()
					,b = stack.pop();	
			stack.push(Math.pow(b,a));
		}
		return 0;
	}

	@Override
	public int dup() throws Exception {
		synchronized (stack) {
			stack.push(stack.peek());
		}
		return 0;
	}

}
