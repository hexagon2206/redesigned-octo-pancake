package mware_lib;

/**
 * @author lukas_luehr
 * an response for a request
 */
public class Response implements Message{
	/**
	 * the ID of the Request, this response belondes to
	 */
	public int requestID;
	
	/**
	 * the Value which has be returned
	 */
	public Object value;
}
