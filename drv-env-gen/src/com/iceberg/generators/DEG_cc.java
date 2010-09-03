package com.iceberg.generators;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.List;
import java.util.Properties;

import com.iceberg.Logger;
import com.iceberg.generators.SequenceParams.Length;

/*
 * формат объектника таков, что можно узнать
 * где и какая метка сгенерирована
 * 
 * то есть расставлять номера main_generator будет на этапе линковки
 * 
 */
public class DEG_cc {
	
	private static final String usageString = 
		"USAGE: java -ea -jar ldv_cc.jar (input_file (--main|--nomain]))*"
		+ "-o output_file -c unique_id -props properties_file gcc_options";
	
	private static List<String> inputFiles = new ArrayList<String>();
	private static String outputFile;
	private static String unique_id;
	private static String propsFileName;
	private static Properties properties;
	private static EnvParams paramsList[]; 
	private static List<Boolean> generateArray = new ArrayList<Boolean>();
	private static final String name = "ldv-cc";
	
	@SuppressWarnings("unused")
	private static EnvParams[] getAllParamVariations() {
		List<EnvParams> list = new ArrayList<EnvParams>();
		list.add(new PlainParams(false, false));
		list.add(new PlainParams(true, false));
		list.add(new PlainParams(true, true));
		
		list.add(new SequenceParams(true,false,Length.one));
		list.add(new SequenceParams(true,false,Length.infinite));
		list.add(new SequenceParams(true,false,3));
		list.add(new SequenceParams(false,false,Length.one));
		list.add(new SequenceParams(false,false,Length.infinite));
		list.add(new SequenceParams(false,false,3));
		
		list.add(new SequenceParams(true,true,Length.one));
		list.add(new SequenceParams(true,true,Length.infinite));
		list.add(new SequenceParams(true,true,3));
		list.add(new SequenceParams(false,true,Length.one));
		list.add(new SequenceParams(false,true,Length.infinite));
		list.add(new SequenceParams(false,true,3));
		return list.toArray(new EnvParams[0]);
	}
	
	public static void main(String[] args) {
		if(!getOpts(args)) {
			System.err.println(usageString);
			System.exit(1);
		}
		try {
			for(int i=(outputFile.length()-1); i>=0; i--) {
				if(outputFile.charAt(i)=='/') {
					String outputFileDirsBeforeIt = outputFile.substring(0,i);
					File outputDirsBeforeFile = new File(outputFileDirsBeforeIt);
					if(!outputDirsBeforeFile.exists())
						outputDirsBeforeFile.mkdirs();
					break;
				}
			}
			FileWriter outputWriter = new FileWriter(outputFile);
			for(int i=0; i<inputFiles.size(); i++) {
				Logger.debug("Start generator for: \""+inputFiles.get(i)+"\" file.");
				
				if(generateArray.get(i)) {
					DegResult res = MainGenerator.deg(properties, inputFiles.get(i), unique_id, paramsList);
					if(res.isSuccess()) {
						for(String id : res.getMains()) {
							outputWriter.append(inputFiles.get(i) 
									+ ":-DLDV_MAIN" + id + "\n");							
						}
					}
				}
			}
			outputWriter.close();
		} catch (Exception e) {
			e.printStackTrace();
			System.exit(1);
		}
	}
	
	private static boolean getOpts(String[] args) {
		Logger.getLogLevelFromEnv();
		Logger.setName(name);
		
		if(args.length==0) {
			Logger.err("Empty options");
			return false;
		}
		
		int i;
		for(i=0; i<args.length && !args[i].equals("-o"); i++ ) {
			File inputFile = new File(args[i]);
			if(!inputFile.exists()) {
				Logger.warn("Input file does't exists: \""+args[i]+"\"");
				//return false;
			}
			inputFiles.add(args[i]);
			i++;
			Logger.debug(args[i]);
			if(args[i].equals("--main")) {
				generateArray.add(true);				
			} else if(args[i].equals("--nomain")){ 
				generateArray.add(false);	
			} else {
				assert false;
				Logger.err("One of --main or --nomain should be specified");
				return false;				
			}
		}
		
		if(inputFiles.size()==0) {
			Logger.err("No input files.");
			return false;
		}
			
		if(!args[i++].equals("-o")) {
			Logger.err("After input files must be \"-o outputfile\".");
			return false;
		}
		
		File outputFileObj = new File(args[i]);
		if(outputFileObj.exists()) {
			Logger.warn("Output file already exists: \""+args[i]+"\".");
		}
		
		outputFile = args[i++];
		
		if(!args[i++].equals("-c")) {
			Logger.err("After output file must be \"-c uniqueid\".");
			return false;
		}
		unique_id = args[i++];
		
		if(!args[i++].equals("-props")) {
			Logger.err("After uniqueid must be \"-props path_to_properties\".");
			return false;
		}
		
		propsFileName = args[i]; 
		
		properties = new Properties(); 
		if(!loadFile(properties, propsFileName, null)) {
			Logger.warn("Properties file not loaded " + propsFileName);
			return false;
		}
		
		paramsList = EnvParams.loadParameters(properties);
		
		if(paramsList==null || paramsList.length==0) {
			Logger.err("Properties file should define at least one environment model");
			return false;
		}		
		
		return true;
	}
	
	private static boolean loadFile(Properties prop, String fileName, Class<?> codeBase) {
		InputStream is = null;
		
		try {
	    	File f = new File(fileName);
	    	if (f.exists()) {
	    		Logger.trace("Open file " + fileName);
	    		is = new FileInputStream(f);
	    	} else {
	    		// try to load as a resource (from jar)
	    		Logger.trace("Try to load as resource");
	    		Class<?> clazz = (codeBase != null) ? codeBase : EnvParams.class;
	    		is = clazz.getResourceAsStream(fileName);
	    	}

	    	if (is != null) {
	    		Logger.trace("Load properties");
	    		prop.load(is);
	    		is.close();
	    		return true;
	    	}
		} catch (IOException iex) {
			iex.printStackTrace();
    		Logger.warn(iex.getMessage());
			return false;
		}
		return false;
	}		
}	
