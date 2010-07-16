package com.iceberg.generators;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

import com.iceberg.Logger;

/*
 * формат объектника таков, что можно узнать
 * где и какая метка сгенерирована
 * 
 * то есть расставлять номера main_generator будет на этапе линковки
 * 
 */
public class DEG_cc {
	
	//private static final String usageString = "USAGE: java -ea -jar ldv_cc.jar input_files -o output_file options";
	private static List<String> inputFiles = new ArrayList<String>();
	private static String outputFile;
	private static String counter;
	private static List<Boolean> generateArray = new ArrayList<Boolean>();
	private static final String name = "ldv-cc";
	
	public static void main(String[] args) {
		if(!getOpts(args))
			System.exit(1);
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
				if(generateArray.get(i) && MainGenerator.deg(inputFiles.get(i),counter))
					outputWriter.append(inputFiles.get(i)+":-DLDV_MAIN"+counter);
			}
			outputWriter.close();
		} catch (IOException e) {
			System.exit(1);
		}
	}
	
	private static boolean getOpts(String[] args) {
		Logger.getLogLevelFromEnv();
		Logger.setName(name);
		
		if(args.length==0) {
			Logger.err("empty options");
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
			if(args[i].equals("--main"))
				generateArray .add(true);
			else if(args[i].equals("--nomain"))
				generateArray.add(false);
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
			Logger.err("After input files must be \"-c number\".");
			return false;
		}
		counter = args[i];
		return true;
	}
}	
