package idl_compiler;

import idl_compiler.IDLCompiler.SupportedDataTypes;

public class MethodeParamData {
	MethodeParamData(SupportedDataTypes type,String name){
		this.type = type;
		this.name=name;
	}
	public final SupportedDataTypes type;
	public final String name;
}
