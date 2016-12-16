package mware_lib;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.lang.reflect.InvocationTargetException;
import java.nio.BufferUnderflowException;
import java.nio.ByteBuffer;

public class Decoder {
	static final int TYPE_INT=1;
	static final int TYPE_DOUBLE=2;
	static final int TYPE_STRING=3;
	static final int TYPE_EXCEPTION=4;
	
	public static byte[] request2Bytes(Request re) throws IOException{
		int requestID=re.requestID;
		String objName=re.obj;
		String methodeName=re.methode;
		Object[] args = re.args;
		
		
		ByteArrayOutputStream baos = new ByteArrayOutputStream();
		ByteBuffer bb=ByteBuffer.allocate(Integer.BYTES);
		bb.putInt(0);
		baos.write(bb.array());
		
		bb.putInt(0,requestID);
		baos.write(bb.array());
		
		baos.write(toByteArray(objName));
		baos.write(toByteArray(methodeName));
		
		bb.putInt(0,args.length);
		baos.write(bb.array());
		
		for(Object o : args){
			baos.write(toByteArray(o));
		}
		
		return baos.toByteArray();
	}
	
	public static Request bytes2request(byte[] bytes) throws Exception{
		ByteBuffer bb = ByteBuffer.wrap(bytes);
		return bytes2request(bb);
	}
	public static Request bytes2request(ByteBuffer bb) throws InstantiationException, IllegalAccessException, IllegalArgumentException, InvocationTargetException, NoSuchMethodException, SecurityException, ClassNotFoundException{
		Request toret = new Request();
		if(0!=bb.getInt()){
			return null;
		}
		toret.requestID = bb.getInt();
		toret.obj = (String)toObj(bb);
		toret.methode = (String)toObj(bb);
		int objcount = bb.getInt();
		
		toret.args = new Object[objcount];
		for(int i = 0 ; i <objcount ; i++ ){
			toret.args[i] = toObj(bb);
		}
		return toret;
	}
	
	public static byte[] response2Bytes(Response re) throws IOException{
		int requestID=re.requestID;
		Object value = re.value;
		
		ByteArrayOutputStream baos = new ByteArrayOutputStream();
		ByteBuffer bb=ByteBuffer.allocate(Integer.BYTES);
		bb.putInt(1);
		baos.write(bb.array());
		
		bb.putInt(0,requestID);
		baos.write(bb.array());
		
		baos.write(toByteArray(value));
		
		return baos.toByteArray();		
	}
	
	public static Response bytes2response(byte[] data) throws InstantiationException, IllegalAccessException, IllegalArgumentException, InvocationTargetException, NoSuchMethodException, SecurityException, ClassNotFoundException{
		ByteBuffer bb = ByteBuffer.wrap(data);
		return response2Bytes(bb);
	}
	public static Response response2Bytes(ByteBuffer bb ) throws InstantiationException, IllegalAccessException, IllegalArgumentException, InvocationTargetException, NoSuchMethodException, SecurityException, ClassNotFoundException{

		Response toret = new Response();
		if(bb.getInt()!=1){
			return null;
		}
		toret.requestID= bb.getInt();
		toret.value = toObj(bb);
		
		return toret;		
	}
	
	public static byte[] toByteArray(Object data) throws IOException{
		ByteArrayOutputStream baos = new ByteArrayOutputStream();
		ByteBuffer bb ;
		if(data instanceof Integer){
			bb = ByteBuffer.allocate(Integer.BYTES);
			bb.putInt(TYPE_INT);
			baos.write(bb.array());
			bb.putInt(0, (Integer) data);
			baos.write(bb.array());
			
		}else if(data instanceof Double){
			bb = ByteBuffer.allocate(Integer.BYTES);
			bb.putInt(TYPE_DOUBLE);
			baos.write(bb.array());
			bb = ByteBuffer.allocate(Double.BYTES);
			bb.putDouble((Double) data);
			baos.write(bb.array());		
		}else if(data instanceof String){
			bb = ByteBuffer.allocate(Integer.BYTES);
			bb.putInt(TYPE_STRING);
			baos.write(bb.array());
			byte[] sdata = ((String) data).getBytes();
			bb.putInt(0,sdata.length);
			baos.write(bb.array());
			baos.write(sdata);
		}else if(data instanceof Exception){
			bb = ByteBuffer.allocate(Integer.BYTES);
			bb.putInt(TYPE_EXCEPTION);
			baos.write(bb.array());
			Exception e = (Exception) data;
			
			byte[] className = e.getClass().getName().getBytes();
			bb.putInt(0,className.length);
			baos.write(bb.array());
			baos.write(className);
			
			byte[] msgText = e.getMessage().getBytes();
			bb.putInt(0,msgText.length);
			baos.write(bb.array());
			baos.write(msgText);
		}else{
			return null;
		}
		return baos.toByteArray();
	}

	public static Object toObj(byte[] toret) throws InstantiationException, IllegalAccessException, IllegalArgumentException, InvocationTargetException, NoSuchMethodException, SecurityException, ClassNotFoundException{
		ByteBuffer in = ByteBuffer.wrap(toret);
		return toObj(in);
	}
	public static Object toObj(ByteBuffer in) throws InstantiationException, IllegalAccessException, IllegalArgumentException, InvocationTargetException, NoSuchMethodException, SecurityException, ClassNotFoundException{
		int type = in.getInt();
		switch(type){
		case TYPE_INT:
			return in.getInt();
		case TYPE_DOUBLE:
			return in.getDouble();
		case TYPE_STRING:
			int lengthstr = in.getInt();
			byte[] strdata = new byte[lengthstr];
			in.get(strdata);
			return new String(strdata);
		case TYPE_EXCEPTION:
			int lengthClassName = in.getInt();
			byte[] strName = new byte[lengthClassName];
			in.get(strName);
			String className =  new String(strName);
			
			lengthClassName = in.getInt();
			strName = new byte[lengthClassName];
			in.get(strName);
			String msg =  new String(strName);
			
			return Class.forName(className).getConstructor(String.class).newInstance(msg);			
		}
		return null;
	}
	public static Message decode(ByteArrayOutputStream baos) throws InstantiationException, IllegalAccessException, IllegalArgumentException, InvocationTargetException, NoSuchMethodException, SecurityException, ClassNotFoundException, IOException  {
		ByteBuffer bb = ByteBuffer.wrap(baos.toByteArray());
		Message m;
		try{
			m = bytes2request(bb);
			if(m==null){
				bb.position(0);
				m = response2Bytes(bb);
			}
			if(m!=null){
				baos.reset();
				int remaining = bb.remaining();
				if(remaining>0){
					byte[] rest = new byte[remaining];
					bb.get(rest);
					baos.write(rest);	
				}
			}
		}catch(BufferUnderflowException e){
			m = null;
		}
		return m;
	}

	
}
