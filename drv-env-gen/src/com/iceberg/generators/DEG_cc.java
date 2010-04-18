package com.iceberg.generators;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

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
			for(int i=0; i<inputFiles.size(); i++) 
				if(MainGenerator.deg(inputFiles.get(i),0))
					outputWriter.append(inputFiles.get(i)+":-DLDV_MAIN"+counter);
			outputWriter.close();
		} catch (IOException e) {
			System.exit(1);
		}
	}
	
	private static boolean getOpts(String[] args) {
		if(args.length==0) {
			System.out.println("ldv_cc: ERROR: empty options");
			return false;
		}
		
		int i;
		for(i=0; i<args.length && !args[i].equals("-o"); i++ ) {
			File inputFile = new File(args[i]);
			if(!inputFile.exists()) {
				System.out.println("ldv_cc: ERROR: Input file does't exists: \""+args[i]+"\"");
				return false;
			}
			inputFiles.add(args[i]);
		}
		
		if(inputFiles.size()==0) {
			System.out.println("ldv_cc: ERROR: No input files.");
			return false;
		}
			
		if(!args[i++].equals("-o")) {
			System.out.println("ldv_cc: ERROR: After input files must be \"-o outputfile\".");
			return false;
		}
		
		//File outputFileObj = new File(args[i]);
		//if(outputFileObj.exists()) {
				//return false;
		//}
		outputFile = args[i++];
		
		if(!args[i++].equals("-c")) {
			System.out.println("ldv_cc: ERROR: After input files must be \"-c number\".");
			return false;
		}
		counter = args[i];
		return true;
	}
}	
