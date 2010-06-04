package com.iceberg.generators;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.FileWriter;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

import com.iceberg.Logger;

public class DEG_ld {
	//private static final String usageString = "USAGE: java -ea -jar ldv_cc.jar input_files -o output_file options";
	private static List<String> inputFiles = new ArrayList<String>();
	private static String outputFile; 
	
	private static final String name = "ldv-ld";

	public static void main(String[] args) {
		if(!getOpts(args))
			System.exit(1);
		String buffer = "";
		for(int i=0; i<inputFiles.size(); i++) {
			String tmp;
			StringBuffer sbuffer=new StringBuffer();
			try {
				BufferedReader fin = new BufferedReader(new FileReader(inputFiles.get(i)));
				while((tmp=fin.readLine())!=null)
				{
					sbuffer.append("\n");
					sbuffer.append(tmp);
				}
				fin.close();
			} catch (FileNotFoundException e)
			{
				Logger.warn("File not found: \""+inputFiles.get(i)+"\".");
				continue;
			} catch (IOException e) {
				Logger.warn("IO error found while read file: \""+inputFiles.get(i)+"\".");
				continue;
			}
			buffer += sbuffer.toString();
			//buffer += FSOperationsBase.readFileCRLF(inputFiles.get(i));
		}
		String mains[] = buffer.split("\n");
			
		for(int i=(outputFile.length()-1); i>=0; i--) {
			if(outputFile.charAt(i)=='/') {
				String outputFileDirsBeforeIt = outputFile.substring(0,i);
				File outputDirsBeforeFile = new File(outputFileDirsBeforeIt);
				if(!outputDirsBeforeFile.exists())
					outputDirsBeforeFile.mkdirs();
				break;
			}
		}
			
		File outputFileObj = new File(outputFile);
		if(outputFileObj.exists())
			outputFileObj.delete();
		try {
			FileWriter fw = new FileWriter(outputFileObj);
			for(int i=0; i<mains.length; i++) {
				if(mains[i].trim().length()!=0)
					fw.append(mains[i].split(":")[1]+"\n");
			}
			fw.close();
		} catch (IOException e) {
			System.out.println("ldv_ld: ERROR: Can't open for write output file !");
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
			if(!inputFile.exists())
				Logger.warn("Input file not found: \""+args[i]+"\".");
			inputFiles.add(args[i]);
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
		if(outputFileObj.exists())
				return false;
		outputFile = args[i];

		return true;
	}
	
}
