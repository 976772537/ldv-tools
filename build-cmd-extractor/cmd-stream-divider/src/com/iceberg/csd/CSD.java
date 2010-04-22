package com.iceberg.csd;

import java.io.File;
import java.io.IOException;

import javax.xml.parsers.ParserConfigurationException;

import org.xml.sax.SAXException;

import com.iceberg.csd.cmdstream.CmdStream;

public class CSD {
	
	private static String basedir = null;
	private static String cmdfile = null;
	public static  boolean driversplit= false;
	public static  boolean fullcopy = false;
	public static int ldv_debug=0;
	public static String cmdfileout = null;
	private static String WORK_DIR = null;
	private static boolean printdigraph = false;
	private static final String usageString = "csd: USAGE: WORK_DIR=workdir <LDV_DEBUG=level> java -ea -jar cmd-stream-divider.jar --basedir=basedir --cmdfile=cmdxmlin --cmdfile-out=outfilename";
	
	
	public static void main(String[] args) {
		if(!getOpts(args)) 
			System.exit(-1);
		try {
			CmdStream cmdstream = CmdStream.getCmdStream(cmdfile, WORK_DIR+"/"+basedir);
			cmdstream.generateTree(WORK_DIR+"/"+basedir,printdigraph,driversplit,fullcopy);
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
		if(args.length < 2 ) {
			System.out.println(usageString);
			return false;
		}	
		
		WORK_DIR = System.getenv("WORK_DIR");
		if(WORK_DIR == null || WORK_DIR.length() == 0) {
			System.out.println("ERROR: setup WORK_DIR var before!");
			System.out.println(usageString);
			return false;
		}
		
		String LDV_DEBUG = System.getenv("LDV_DEBUG");
		if(LDV_DEBUG!=null) {
			if(LDV_DEBUG.equals("INFO"))
				ldv_debug=20;
			else if(LDV_DEBUG.equals("NORMAL"))
				ldv_debug=10;
			else if(LDV_DEBUG.equals("DEBUG"))
				ldv_debug=30;
			else if	(LDV_DEBUG.equals("TRACE"))
				ldv_debug=40;
			else if(LDV_DEBUG.equals("ALL"))
				ldv_debug=100;
		}

		
		for(int i=0; i<args.length; i++) {
			if(args[i].contains("--basedir=")) {
				basedir = args[i].replace("--basedir=", "").trim();
			} else
			if(args[i].contains("--cmdfile=")) {
				cmdfile = args[i].replace("--cmdfile=", "").trim();
			} else
			if(args[i].equals("--split-on")) {
				driversplit = true;
			} else             
			if(args[i].equals("--full-copy")) {
				fullcopy = true;
			} else
			if(args[i].contains("--cmdfile-out=")) {
				cmdfileout = args[i].replace("--cmdfile-out=", "").trim();
			} else
			if(args[i].equals("--print-digraph")) {
				printdigraph = true;
			} else	{
				System.out.println("csd: ERROR: Unknown parameter: \""+args[i]+"\".");
				System.out.println(usageString);
				return false;
			}
		}
		
		if(basedir==null || basedir.length()==0) {
			System.out.println("csd: ERROR: Setup option \"--basedir\" - not set.");
			return false;			
		}		

		File wokrFile = new File(WORK_DIR);
		if(!wokrFile.exists() || !wokrFile.isDirectory()) {
			System.out.println("csd: ERROR: WORK_DIR directory: \""+WORK_DIR+"\" - not exists.");
			return false;
		}
		
		File wokrdirFile = new File(WORK_DIR+"/"+basedir);
		if(!wokrdirFile.exists()) {
			System.out.println("csd: WARNING: Temp directory: \""+WORK_DIR+"/"+basedir+"\" - not exists. Try to create it");
			wokrdirFile.mkdirs();
		}
		
		if(cmdfile==null || cmdfile.length()==0) {
			System.out.println("csd: ERROR: Setup option \"--cmdfile\" - and tru again.");
			return false;			
		}
		
		File cmdFile = new File(cmdfile);
		if(!cmdFile.exists()) {
			System.out.println("csd: ERROR: Can't find input cmdfile: \""+cmdfile+"\".");
			return false;
		}
		
		if(cmdfileout==null || cmdfileout.length()==0) {
			System.out.println("csd: WARNING: Option \"--cmdfile-out\" - not set. Use default \"cmd_after_csd\".");
			cmdfileout="cmd_after_csd";		
		}
				
		return true;
	}
}
