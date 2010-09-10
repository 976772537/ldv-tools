package org.linuxtesting.ldv.online.vs.client;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.FileWriter;
import java.io.IOException;
import java.util.List;
import java.util.Map;

import org.linuxtesting.ldv.online.FSOperationBase;
import org.linuxtesting.ldv.online.Utils;
import org.linuxtesting.ldv.online.Logger;
import org.linuxtesting.ldv.online.schelduler.MTask;
import org.linuxtesting.ldv.online.server.ClientConfig;
import org.linuxtesting.ldv.online.server.Config;
import org.linuxtesting.ldv.online.server.ServerThreadEnum;

public class VClient {
	
	public static void main(String[] args) {
		if(args.length!=1) {
			System.out.println("USAGE: java -ea -jar vc.jar client.conf");
			System.exit(1);
		}
		Map<String,String> params = Config.readParameters(args[0]);
		Logger.getLogLevelFromMap(params);
		ClientConfig config = new ClientConfig(params, ServerThreadEnum.VS);
		VClientProtocol protocol = new VClientProtocol(config);
		while(true) {
			MTask task = protocol.VSGetTask();
			if(task == null) {
				Logger.err("Can't get task...");
				System.exit(1);
			} else if (task.getMsg().equals("NO TASKS")) {
				Logger.info("NO tasks...");
				try {
					Thread.sleep(5000);
				} catch (InterruptedException e) {
					e.printStackTrace();
				}	
			} else if (task.getMsg().equals("OK")){
				Logger.debug("Task from user: "+task.getId());
				Logger.info("Start verification...");
				boolean result = startVerification(config, task);
				Logger.info("Verification end.");
				Logger.debug("Try to send results...");
				if(!protocol.VSSendResults(result,task.getId())) {
					Logger.err("Can't send results...");
					System.exit(1);
				}
				Logger.info("Results successfully sending...");
			} else {
				Logger.err("Unknown status...");
				System.exit(1);				
			}
			//break;
		}
	}

	
	public static String getOneDiff(String[] allTasksNewList, String[] allTasksList) {
		for(int i=0; i<allTasksNewList.length; i++) {
			for(int j=0; j<allTasksList.length; j++) {
				if(allTasksNewList[i] == allTasksList[j]) {
					break;
				}
				return allTasksNewList[i];
			}
		}
		return null;
	}
	
	// возвращает строку на репорт
	public static boolean startVerification(ClientConfig config, MTask task) {
		Logger.trace("Before VClient run: ");
		Logger.info("  1. Create workdir (config have corresponding option WorkDir).");
		Logger.info("  2. Put into workdir kernels.");
		Logger.info("  3. Install LDV tools.");
		Logger.info("  4. Set-up variable WorkDir in client config.");
		Logger.info("  5. Set-up variable LDVInstalledDir.");
		File tworkdir = new File(config.getWorkDir()+"/run");
		tworkdir.mkdirs();
		// 1. Create list with bad tasks if it not exists... 
		/*File badlistFile = new File(config.getWorkDir()+"/badlist");
		if(!badlistFile.exists()) {
			FileWriter fw = null;
			try {
				badlistFile.createNewFile();
				// regenerate badlist if tasks exists from previous ldv work //
				File ldvManagerWorkdir =  new File(config.getWorkDir()+"/run/work");
				if(ldvManagerWorkdir.exists()) {
					String[] badTasksList = FSOperationBase.getDirs(ldvManagerWorkdir.getCanonicalPath());
					if(badTasksList!=null && badTasksList.length>0) {
						fw = new FileWriter(badlistFile);
						for(int i=0; i<badTasksList.length; i++) {
							fw.write(badTasksList[i]);
						}
						fw.flush();
					}
				} 
			} catch (IOException e) {
				Logger.err("Can't create file with list of bad tasks.");
				e.printStackTrace();
			} finally {
				if(fw!=null)
					try {
						fw.close();
					} catch (IOException e) {
						// TODO Auto-generated catch block
						e.printStackTrace();
					}
			}
		}*/
		FileOutputStream fis = null;
		try {
			fis = new FileOutputStream(config.getWorkDir()+"/run/"+task.getDriver());
			fis.write(task.getData());
			fis.flush();
			fis.close();
	
			/* get list of all tasks */
			//String[] allTasksList = FSOperationBase.getDirs(config.getWorkDir()+"/run/work");
	
			/* write shell script */
			String startString = "cd "+ config.getWorkDir() +"/run; export PATH=$PATH:" +
			config.getLDVInstalledDir()+"/bin; LDV_DEBUG="+Logger.logLevel+" LDV_TASK_ID="+task.getParentId()+" "+
			config.getLDVManagerStartStaticVariables()+
			" ldv-manager tag=current \"envs="+
			task.getEnv()+".tar.bz2\" \"drivers="+task.getDriver()+"\" \"rule_models="+
			task.getRule()+"\" 2>&1";
			runCommand(config.getWorkDir() +"/start", startString);	
			
			
			File driverFile = new File(config.getWorkDir()+"/run/"+task.getDriver());
			driverFile.delete();
			//  and now upload all paxes
			// 1. Search paxes:
			Logger.debug("Search pax files...");
			List<String> paxList = FSOperationBase.getDirContentRecursivePax(config.getWorkDir() +"/run/finished");
			if(paxList == null || paxList.size()==0) {
				Logger.debug("Can't find pax files - verification failed.");
				
				/* get directory with our task */
				//String[] allTasksNewList = FSOperationBase.getDirs(config.getWorkDir()+"/run/work");
				//String ourTask = getOneDiff(allTasksNewList, allTasksList);
				//assert(ourTask!=null) : " Bad task must be exists in work dir of ldv-manager!";
				/* add our task to badlist */
				//FileWriter fw = new FileWriter(badlistFile);
				//fw.append(ourTask);
				//fw.flush();
				//fw.close();
				/* clean work and finished directories */
				//cleanWorkAndFinishedDirs(config);
				return false;
			} 
			Logger.debug("Number of pax files: "+paxList.size());
			Logger.debug("Start uploading pax files.");
			for(String paxFileString : paxList) {
				// upload pax file
				Logger.debug("Start upload pax file: "+paxFileString);				
				startString = "cd "+ config.getWorkDir() +"/run; export PATH=$PATH:" +
				config.getLDVInstalledDir()+"/bin; LDV_DEBUG="+Logger.logLevel+" LDV_TASK_ID="+task.getParentId()+
				" LDVDB="+config.getStatsDBName()+" LDVUSER="+config.getStatsDBUser()+
				" LDVDBPASSWD="+config.getStatsDBPass()+" LDVDBHOST="+config.getStatsDBHost()+
				" ldv_statuses=1 ldv-upload "+paxFileString+" 2>&1";
				runCommand(config.getWorkDir() +"/start", startString);	
				// delete it
				Logger.debug("Delete pax file: "+paxFileString);
				(new File(paxFileString)).delete();
			}
			Logger.debug("All pax files uploaded.");
			/** TODO: clean ./run directory
			/* For this action ldv-manager must have 
			/* variable for external kernel prepare dir!
			 */
			Logger.debug("Clean node dirs...");
			//cleanWorkAndFinishedDirs(config);
			/* Old clean mechanis */
			String removeCommand =  "cd "+ config.getWorkDir() +"/run; rm -fr ./work ./finished 2>&1";
			runCommand(config.getWorkDir() +"/clean_after_ldv_manager", removeCommand);
			Logger.debug("Clean node dirs successfully finfished.");
			
			return true;
		} catch (FileNotFoundException e) {
			e.printStackTrace();
		} catch (IOException e) {
			e.printStackTrace();
		} finally {
			try {
				fis.close();
			} catch (IOException e) {
				e.printStackTrace();
			}
		}
		return false;
	}
	
	/*private static void cleanWorkAndFinishedDirs(ClientConfig config) {
		// read badlist fil if it exists 
		File badListFile = new File(config.getWorkDir()+"/badlist");
		if(badListFile.exists()) {
			//read list with bad tasks 
		} else {
			File lmWorkDir = new File(config.getWorkDir()+"/run/work");
			File lmFininshedDir = new File(config.getWorkDir()+"/run/finished");
			if(lmWorkDir.exists())
				FSOperationBase.removeDirectoryRecursive(lmWorkDir);
			if(lmFininshedDir.exists())
				FSOperationBase.removeDirectoryRecursive(lmFininshedDir);
		}
	}*/


	public static boolean runCommand(String tempfile, String command) {
		boolean result = false;
		Logger.trace("RUN command:" + command);
		Logger.debug("Write start command in file :" + tempfile);
		File startFile = new File(tempfile);
		FileWriter startFileWriter;
		try {
			startFileWriter = new FileWriter(startFile);
			startFileWriter.write(command);
			startFileWriter.flush();
			startFileWriter.close();
			Utils.runFromFile(tempfile);
			startFile.delete();
			result = true;
		} catch (IOException e) {
			e.printStackTrace();
		}
		return result;
	}
}
