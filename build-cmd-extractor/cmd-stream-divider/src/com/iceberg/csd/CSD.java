package com.iceberg.csd;

import java.io.IOException;

import javax.xml.parsers.ParserConfigurationException;

import org.xml.sax.SAXException;

import com.iceberg.csd.cmdstream.CmdStream;

public class CSD {
	
	private static String basedir = null;
	private static String cmdfile = null;
	public static int ldv_debug=0;
	//private static String cmdfileout = null;
	//private static String WORK_DIR = null;
	private static boolean printdigraph = false;
	private static final String usageString = "csd: USAGE: <LDV_DEBUG=level> java -ea -jar cmd-stream-divider.jar --basedir=basedir --cmdfile=cmdxmlin";
	
	
	public static void main(String[] args) {
		if(!getOpts(args)) 
			System.exit(-1);
		try {
			CmdStream cmdstream = CmdStream.getCmdStream(cmdfile, basedir);
			cmdstream.generateTree(basedir,printdigraph);
		
	
		} catch (ParserConfigurationException e1) {
			System.out.println("csd: ERROR: parse exception.\n");
			System.exit(-1);
		} catch (SAXException e1) {
			System.out.println("csd: SAX exception.\n");
			System.exit(-1);
		} catch (IOException e1) {
			System.out.println("csd: IO exception.\n");
			System.exit(-1);
		}
	}
	
	private static boolean getOpts(String[] args) {
		if(args.length != 2 ) {
			System.out.println(usageString);
			return false;
		}	
		
		/*WORK_DIR = System.getenv("WORK_DIR");
		if(WORK_DIR == null || WORK_DIR.length() == 0) {
			System.out.println("ERROR: setup WORK_DIR var before!");
			System.out.println(usageString);
			return false;
		}*/
		String LDV_DEBUG = System.getenv("LDV_DEBUG");
		if(LDV_DEBUG == "INFO" || LDV_DEBUG == "info") {
			ldv_debug=40;
			return false;
		}

		
		for(int i=0; i<args.length; i++) {
			if(args[i].contains("--basedir=")) {
				basedir = args[i].replace("--basedir=", "").trim();
			} else
			if(args[i].contains("--cmdfile=")) {
				cmdfile = args[i].replace("--cmdfile=", "").trim();
			} else
			if(args[i].contains("--print-digraph")) {
				printdigraph = true;
			} else	{
				System.out.println("csd: ERROR: Unknown parameter: \""+args[i]+"\".");
				System.out.println(usageString);
				return false;
			}
		}
		return true;
	}
}
