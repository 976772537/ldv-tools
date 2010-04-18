package com.iceberg.generators;

import java.io.File;
import java.io.FileWriter;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

import com.iceberg.FSOperationsBase;

public class DEG_ld {
	//private static final String usageString = "USAGE: java -ea -jar ldv_cc.jar input_files -o output_file options";
	private static List<String> inputFiles = new ArrayList<String>();
	private static String outputFile; 

	public static void main(String[] args) {
		if(!getOpts(args))
			System.exit(1);
		//try {
			String buffer = "";
			for(int i=0; i<inputFiles.size(); i++) {
				// TODO: replace mains with actuals numbers
				System.out.println("ldv_ld: WARNING: may be some errors in this place !");
				buffer += FSOperationsBase.readFileCRLF(inputFiles.get(i));
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
				System.out.println("ldv_ld: WARNING: Can't open for write output file !");
				System.exit(1);
			}
/*		} catch (IOException e) {
			e.printStackTrace();
			System.exit(1);
		}*/
	}
	
	private static boolean getOpts(String[] args) {
		if(args.length==0) {
			System.out.println("ldv_ld: ERROR: empty options");
			return false;
		}

		int i;
		for(i=0; i<args.length && !args[i].equals("-o"); i++ ) {
			//File inputFile = new File(args[i]);
			//if(!inputFile.exists())
				//return false;
			inputFiles.add(args[i]);
		}
		
		if(inputFiles.size()==0) {
			System.out.println("ldv_ld: ERROR: No input files.");
			return false;
		}
		
		
		if(!args[i++].equals("-o")) {
			System.out.println("ldv_cc: ERROR: After input files must be \"-o outputfile\".");
			return false;
		}
		
		File outputFileObj = new File(args[i]);
		if(outputFileObj.exists())
				return false;
		outputFile = args[i];

		return true;
	}
	
}
