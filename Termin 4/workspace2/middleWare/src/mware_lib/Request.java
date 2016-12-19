package mware_lib;

/**
 * @author lukas_luehr
 * a request for an remote call
 */
public class Request implements Message{
	
	/**
	 * The ID of the Request
	 */
	public int requestID;
	
	/**
	 * The Name Of the service to use
	 */
	public String obj;
	
	/**
	 * The Name of the Methode
	 */
	public String methode;
	
	/**
	 * the arguments of the Methode
	 */
	public Object[] args;
}
