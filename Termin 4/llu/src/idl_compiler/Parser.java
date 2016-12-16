package idl_compiler;

import idl_compiler.IDLCompiler.MethodData;
import idl_compiler.IDLCompiler.SupportedDataTypes;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.IOException;
import java.io.OutputStream;
import java.io.OutputStreamWriter;
import java.io.PrintWriter;
import java.io.Reader;
import java.util.ArrayList;

/**
 * Parser main class.
 * 
 * @author  (c) H. Schulz, 2016  
 * This programme is provided 'As-is', without any guarantee of any kind, implied or otherwise and is wholly unsupported.
 * You may use and modify it as long as you state the above copyright.
 *
 */
public class Parser {
	public static final String BEGIN = "{";
	public static final String BEGIN_REGEX = "\\{";
	public static final String END = "};";
	public static final String MODULE = "module";
	public static final String CLASS = "class";
	public static final String PARENTHESIS_OPEN = "\\(";
	public static final String PARENTHESIS_CLOSE = "\\)";
	public static final String PARENTHESES = "[(|)]";
	public static final String PARAM_SEPARATOR = ",";
	
	/**
	 * File reader counting lines.
	 * @author   (c) H. Schulz, 2016    This programme is provided 'As-is', without any guarantee of any kind, implied or otherwise and is wholly unsupported.  You may use and modify it as long as you state the above copyright.
	 */
	private static class IDLfileReader extends BufferedReader {
		/**
		 * @uml.property  name="lineNo"
		 */
		private int lineNo;
		
		public IDLfileReader(Reader in) {
			super(in);
			lineNo = 0;
		}
		
		public String readLine() throws IOException {
			lineNo++;
			return super.readLine();
		}
		
		/**
		 * @return
		 * @uml.property  name="lineNo"
		 */
		public int getLineNo() {
			return lineNo;
		}
	}
	
	/**
	 * For printing compilation errors
	 * 
	 * @param lineNo
	 * @param text
	 */
	private static void printError(int lineNo, String text) {
		System.err.println("Line " + lineNo + ": " + text);
	}
	
	/**
	 * Parse IDL Module in given file.
	 * 
	 * @param in file reader
	 * @return
	 * @throws IOException
	 */
	private static IDLmodule parseModule(IDLfileReader in) throws IOException {
		IDLclass newClass;

		String line = in.readLine();		
		String tokens[] = (line.split(BEGIN_REGEX)[0]).trim().split(" ");
		
		if (tokens != null && tokens.length>1 && tokens[0].equals(MODULE) && tokens[1] !=null && tokens[1].length()>0) {
			IDLmodule currentModule = new IDLmodule(tokens[1]);
			do {
				// parse containing classes
				newClass = parseClass(in, currentModule.getModuleName());
				if (newClass!=null) currentModule.addClass(newClass);
				
				// try to read next module
				tokens = (line.split(BEGIN_REGEX)[0]).trim().split(" ");
			} while (newClass!=null);
						
			return currentModule;
			
			
		} else {
			printError(in.getLineNo(), "Error parsing module. '" + line + "'");
			return null;
		}
	}
	
	/**
	 * Parse (next) class in a file/module.
	 * 
	 * @param in file reader
	 * @param currentModuleName name of the module currently being parsed.
	 * @return the class parsed or null if there is no class left in the file
	 * @throws IOException
	 */
	private static IDLclass parseClass(IDLfileReader in, String currentModuleName) throws IOException {
		ArrayList<MethodData> methodList = new ArrayList<MethodData>();
		
		String line = in.readLine();
		if (line != null) {
			String tokens[] = (line.split(BEGIN_REGEX)[0]).trim().split(" ");
			if (tokens != null && tokens.length > 1 && tokens[0].equals(CLASS)
					&& tokens[1] != null && tokens[1].length() > 0) {
				// name of this class
				String className = tokens[1];

				// read methods
				line = in.readLine();
				while (line != null && !line.contains(END)) {
					String[] tokens2 = line.trim().split(PARENTHESES);

					String[] tokens3 = tokens2[0].split(" ");
					String rTypeString = tokens3[0]; // return value
					String methodName = tokens3[1]; // method name

					MethodeParamData paramTypes[] = parseParams(in.getLineNo(),tokens2[1]);

					// into data container
					methodList.add(new MethodData(methodName, IDLCompiler.getSupportedTypeForKeyword(rTypeString), paramTypes));
					line = in.readLine();
				}

				// read class end
				if (line == null || !line.contains(END)) {
					printError(in.getLineNo(), "Error parsing class "
							+ className + ": no end mark '" + line + "'");
				}

				// method data -> array
				MethodData methodArray[] = new MethodData[methodList.size()];

				//return IDL class
				return new IDLclass(className, currentModuleName,
						methodList.toArray(methodArray));
			} else {
				if (line.contains(END)) {
					return null;
				} else {
					printError(in.getLineNo(), "Error parsing class.'" + line
							+ "'");
					return null;
				}
			}
		} else {
			printError(in.getLineNo(), "Attempt to read beyond end of file.");
			return null;
		}
	}
	
	/**
	 * Evaluate parameter list. (No reading done here!)
	 * 
	 * @param lineNo
	 * @param paramList
	 * @return
	 */
	private static MethodeParamData[] parseParams(int lineNo, String paramList) {
		if (paramList != null && paramList.length() > 0) {
			String[] paramEntries = paramList.trim().split(PARAM_SEPARATOR);
			
			// param data container
			MethodeParamData paramTypes[] = new MethodeParamData[paramEntries.length];
						
			for (int i=0; i<paramEntries.length; i++) {
				String[] typeAndParamName = paramEntries[i].trim().split(" ");
				
				// 0: type, 1: name
				SupportedDataTypes type = idl_compiler.IDLCompiler.getSupportedTypeForKeyword(typeAndParamName[0]);
				//TODO Param Types rein hac
				if (type == null) {
					printError(lineNo, "Error parsing param list");
					return null;
				}else{
					paramTypes[i] = new MethodeParamData(type, typeAndParamName[1]);
				}
			}
			return paramTypes;
		} else {
			return new MethodeParamData[0];  // empty list
		}
	}	

	/**
	 * @param args
	 */
	public static void main(String[] args) {
		String IDLfileName = "./calc.idl";   //TODO should be parameterised.
		
		try {
			IDLfileReader in = new IDLfileReader(new FileReader(IDLfileName));
			IDLmodule module = parseModule(in);  // Parse IDL file
			
			// output of what we parsed from IDL file (just for testing)
			printModule(module);
			toJava(module, ".\\out\\");
			
		} catch (FileNotFoundException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}

	/**
	 * testing output & example on how to access class and method data of an IDL module.
	 * 
	 * @param module
	 */
	private static void printModule(IDLmodule module) {
		System.out.println();
		System.out.println("module: "+module.getModuleName());
		
		// classes
		IDLclass[] classes = module.getClasses();
		for (int i=0; i<classes.length; i++) {
			System.out.println(" class: " + classes[i].getClassName());
			
			// methods
			MethodData[] methods = classes[i].getMethods();
			for (int k=0; k<methods.length; k++) {
				System.out.print("  method: " + IDLCompiler.getSupportedIDLDataTypeName(methods[k].getReturnType()) 
						+ " " + methods[k].getName() + " ");
				
				// parameters
				MethodeParamData[] paramTypes = methods[k].getParamTypes();
				for (int m=0; m<paramTypes.length; m++) {
					System.out.print(paramTypes[m].name + " : " + IDLCompiler.getSupportedIDLDataTypeName(paramTypes[m].type) + " ");
				}
				System.out.println();
			}
		}
	}
	
	public static void toJava(IDLmodule module,String outputDir){
		for(IDLclass c:module.getClasses()){
			toBaseImplClass(c,outputDir);
		}	
	}
	private static String toFileName(IDLclass c){
		return "_"+c.getClassName()+"ImplBase";
	}
	
	
	private static void toMethode(MethodData m,PrintWriter writer){
		writer.write("\tpublic abstract " + IDLCompiler.getSupportedJavaDataTypeName(m.getReturnType()) +" " + m.getName() + "(\n");
		int n = 0;
		for(MethodeParamData t : m.getParamTypes()){
			writer.write("\t\t"+IDLCompiler.getSupportedJavaDataTypeName(t.type)+" "+t.name+"\n");
		}
		writer.write("\t\t);\nn");
	}
	private static void toBaseImplClass(IDLclass c,String outputDir){
		PrintWriter writer = null;
		try{
			String className=toFileName(c);
			writer = new PrintWriter(outputDir+className+".java", "UTF-8");
		    writer.write("package "+ c.getModuleName() + "\n");
		    
		    writer.write("public abstract class " + className + " {\n\n");
		    writer.write("\tpublic static "+className+" narrowCast(Object rawObjectRef) {\n"+
		    	"\t\t return ("+className+")rawObjectRef;\n"+
		    	"\n\t  }\n");
		    
		    for(MethodData m:c.getMethods()){
		    	toMethode(m,writer);
		    }
		    
		    
		    writer.write("}\n");
		} catch (IOException e) {
		   // do something
		} finally {
			if(writer!=null) writer.close();
		}
	}
}
