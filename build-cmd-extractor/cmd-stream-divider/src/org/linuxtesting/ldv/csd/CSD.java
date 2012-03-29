/*
 * Copyright (C) 2010-2012
 * Institute for System Programming, Russian Academy of Sciences (ISPRAS).
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package org.linuxtesting.ldv.csd;

import java.io.File;
import java.io.IOException;
import javax.xml.ws.Endpoint;

import org.linuxtesting.ldv.csd.cmdstream.CmdStream;
import org.linuxtesting.ldv.csd.utils.Logger;
import org.linuxtesting.ldv.csd.ws.CSDWebService;

public class CSD {
	
	private static String basedir = null;
	private static String wsdlAddr = null;
	private static String statefile = null;
	public static  boolean driversplit= true;
	public static  boolean fullcopy = false;
	public static int ldv_debug=0;
	public static String cmdfileout = null;
	private static String WORK_DIR = null;
	private static final String usageString = "csd: USAGE: WORK_DIR=workdir <LDV_DEBUG=level> java -ea -jar cmd-stream-divider.jar --basedir=basedir --cmdfile=cmdxmlin --cmdfile-out=outfilename --state-file=statefile";
	private static final String name = "CSD";
	public static String tagbd;
	
	public static volatile boolean term = false;
	
	public static void main(String[] args) throws IOException, InterruptedException {
		   if(!getOpts(args)) 
			System.exit(-1);
		
			// Create new cmdstream
			CmdStream cmdstream = new CmdStream(WORK_DIR+"/"+basedir,tagbd, fullcopy,statefile);
			
			// Create web service
                        CSDWebService ws = new CSDWebService(cmdstream);
                        
			// Start web service
			Endpoint.publish(wsdlAddr, ws);
	}
	
	private static boolean getOpts(String[] args) {
		Logger.getLogLevelFromEnv();
		Logger.setName(name);
		
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
			if(args[i].contains("--state-file=")) {
				statefile = args[i].replace("--state-file=", "").trim();
			} else            
			if(args[i].equals("--full-copy")) {
				fullcopy = true;
			} else
			if(args[i].contains("--cmdfile-out=")) {
				cmdfileout = args[i].replace("--cmdfile-out=", "").trim();
			} else
			if(args[i].contains("--tagbd=")) {
				tagbd = args[i].replace("--tagbd=", "").trim();
			} else
			if(args[i].contains("--wsdladdr=")) {
				wsdlAddr = args[i].replace("--wsdladdr=", "").trim();
			} else {				
				Logger.err("Unknown parameter: \""+args[i]+"\".");
				Logger.info(usageString);
				return false;
			}
		}
		
		if(basedir==null || basedir.length()==0) {
			Logger.err("Please, specify \"--basedir\" option.");
			return false;			
		}		

		File workFile = new File(WORK_DIR);
		if(!workFile.exists() || !workFile.isDirectory()) {
			Logger.warn(" WORK_DIR directory: \""+WORK_DIR+"\" - not exists.");
			workFile.mkdirs();
		}
		
		File workdirFile = new File(WORK_DIR+"/"+basedir);
		if(!workdirFile.exists()) {
			//System.out.println("csd: WARNING: Temp directory: \""+WORK_DIR+"/"+basedir+"\" - not exists. Try to create it");
			workdirFile.mkdirs();
		} else {
			Logger.warn("Temp directory: \""+WORK_DIR+"/"+basedir+"\" - already exists.");
			//return false;
		} 
		
		if(wsdlAddr==null || wsdlAddr.length()==0) {
			Logger.err("Setup option \"--wsdladdr\" - and try again.");
			return false;			
		}
		
		if(statefile==null || statefile.length()==0) {
			Logger.err("Setup option \"--state-file\" - and try again.");
			return false;			
		}
		
		File stateFile = new File(statefile);
		if(stateFile.exists()) {
			Logger.warn("State file already exists: \""+statefile+"\".");
			stateFile.delete();
		}
		
		if(cmdfileout==null || cmdfileout.length()==0) {
			Logger.warn("Option \"--cmdfile-out\" - not set. Use default \"cmd_after_csd\".");
			cmdfileout="cmd_after_csd";		
		}
				
		return true;
	}
}
