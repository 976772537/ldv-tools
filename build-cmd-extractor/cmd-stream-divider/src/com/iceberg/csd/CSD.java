package com.iceberg.csd;

import java.io.File;
import java.io.IOException;

import javax.xml.parsers.ParserConfigurationException;

import org.xml.sax.SAXException;

import com.iceberg.csd.cmdstream.CmdStream;
import com.iceberg.csd.utils.Logger;

public class CSD {
	
	private static String basedir = null;
	private static String cmdfile = null;
	private static String statefile = null;
	public static  boolean driversplit= false;
	public static  boolean fullcopy = false;
	public static int ldv_debug=0;
	public static String cmdfileout = null;
	private static String WORK_DIR = null;
	private static boolean printdigraph = false;
	private static final String usageString = "csd: USAGE: WORK_DIR=workdir <LDV_DEBUG=level> java -ea -jar cmd-stream-divider.jar --basedir=basedir --cmdfile=cmdxmlin --cmdfile-out=outfilename --state-file=statefile";
	
	
	public static void main(String[] args) {
		if(!getOpts(args)) 
			System.exit(-1);
		try {
			Logger.trace("Try to get input command stream...");
			CmdStream cmdstream = CmdStream.getCmdStream(cmdfile, WORK_DIR+"/"+basedir);
			Logger.trace("Ok.");
			Logger.trace("Generate new command streams..");
			cmdstream.generateTree(WORK_DIR+"/"+basedir,printdigraph,driversplit,fullcopy,statefile);
			Logger.trace("Ok.");
		} catch (ParserConfigurationException e1) {
			Logger.err("Parse exception");
			System.exit(-1);
		} catch (SAXException e1) {
			Logger.err("SAX exception");
			System.exit(-1);
		} catch (IOException e1) {
			Logger.err("IO exception");
			System.exit(-1);
		}
	}
	
	private static boolean getOpts(String[] args) {
		Logger.getLogLevelFromEnv();
		
		if(args.length < 2 ) {
			Logger.info(usageString);
			return false;
		}	
		
		WORK_DIR = System.getenv("WORK_DIR");
		if(WORK_DIR == null || WORK_DIR.length() == 0) {
			Logger.err("setup WORK_DIR var before!");
			Logger.info(usageString);
			return false;
		}
		
		for(int i=0; i<args.length; i++) {
			if(args[i].contains("--basedir=")) {
				basedir = args[i].replace("--basedir=", "").trim();
			} else
			if(args[i].contains("--cmdfile=")) {
				cmdfile = args[i].replace("--cmdfile=", "").trim();
			} else
			if(args[i].contains("--state-file=")) {
				statefile = args[i].replace("--state-file=", "").trim();
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
				Logger.err("Unknown parameter: \""+args[i]+"\".");
				Logger.info(usageString);
				return false;
			}
		}
		
		if(basedir==null || basedir.length()==0) {
			Logger.err("Setup option \"--basedir\" - not set.");
			return false;			
		}		

		File wokrFile = new File(WORK_DIR);
		if(!wokrFile.exists() || !wokrFile.isDirectory()) {
			Logger.err(" WORK_DIR directory: \""+WORK_DIR+"\" - not exists.");
			return false;
		}
		
		File wokrdirFile = new File(WORK_DIR+"/"+basedir);
		if(!wokrdirFile.exists()) {
//			System.out.println("csd: WARNING: Temp directory: \""+WORK_DIR+"/"+basedir+"\" - not exists. Try to create it");
			wokrdirFile.mkdirs();
		} else {
			Logger.err("Temp directory: \""+WORK_DIR+"/"+basedir+"\" - alredy.");
			return false;
		} 
		
		if(cmdfile==null || cmdfile.length()==0) {
			Logger.err("Setup option \"--cmdfile\" - and try again.");
			return false;			
		}
		
		File cmdFile = new File(cmdfile);
		if(!cmdFile.exists()) {
			Logger.err("Can't find input cmdfile: \""+cmdfile+"\".");
			return false;
		}
		
		if(statefile==null || statefile.length()==0) {
			Logger.err("Setup option \"--state-file\" - and try again.");
			return false;			
		}
		
		File stateFile = new File(statefile);
		if(stateFile.exists()) {
			Logger.err("State file already exists: \""+statefile+"\".");
			return false;
		}
		
		if(cmdfileout==null || cmdfileout.length()==0) {
			Logger.warn("Option \"--cmdfile-out\" - not set. Use default \"cmd_after_csd\".");
			cmdfileout="cmd_after_csd";		
		}
				
		return true;
	}
}
