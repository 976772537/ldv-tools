package com.iceberg.generators;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

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
	private static String counter;
	private static String properties;
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
					DegResult res = MainGenerator.deg(inputFiles.get(i),counter, paramsList);
					if(res.isSuccess()) {
						for(String id : res.getMains()) {
							outputWriter.append(inputFiles.get(i) 
									+ ":-DLDV_MAIN" + id + "\n");							
						}
					}
				}
			}
			outputWriter.close();
		} catch (IOException e) {
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
		counter = args[i++];
		
		if(!args[i++].equals("-props")) {
			Logger.err("After uniqueid must be \"-props path_to_properties\".");
			return false;
		}
		
		properties = args[i]; 
		paramsList = EnvParams.loadParameters(properties);
		
		if(paramsList.length==0) {
			Logger.err("Properties file should define at least one environment model");
			return false;
		}		
		
		return true;
	}
}	
