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
				Logger.err("May be class versions in server and node not synchronized?");
			} else if (task.getMsg().equals("NO TASKS")) {
				Logger.info("NO tasks...");
			} else if (task.getMsg().equals("OK")){
				Logger.debug("Task from user: "+task.getId());
				Logger.info("Start verification...");
				boolean result = startVerification(config, task);
				Logger.info("Verification end.");
				Logger.debug("Try to send results...");
				if(!protocol.VSSendResults(result,task.getId())) {
					Logger.err("Can't send results...");
					continue;
				}
				Logger.info("Results successfully sending...");
			} else {
				Logger.err("Unknown status...");
			}
                        try {
	                       Thread.sleep(5000);
                        } catch (InterruptedException e) {
                              e.printStackTrace();
                        }

			//break;
		}
	}
	
	// возвращает строку на репорт
	public static boolean startVerification(ClientConfig config, MTask task) {
		Logger.trace("Before VClient run: ");
		Logger.info("  1. Create workdir (config have corresponding option WorkDir).");
		Logger.info("  2. Put into workdir kernels.");
		Logger.info("  3. Install LDV tools.");
		Logger.info("  4. Set-up variable WorkDir in client config.");
		Logger.info("  5. Set-up variable LDVInstalledDir.");
		File tworkdir_work = new File(config.getWorkDir()+"/run/errors/work");
		File tworkdir_finished = new File(config.getWorkDir()+"/run/errors/finished");
		tworkdir_work.mkdirs();
		tworkdir_finished.mkdirs();
		/* TODO: move all from dirs finished and work to errors.., */
		FileOutputStream fis = null;
		try {
			fis = new FileOutputStream(config.getWorkDir()+"/run/"+task.getDriver());
			fis.write(task.getData());
			fis.flush();
			fis.close();
	
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
			//FSOperationBase.removeDirectoryRecursive(new File(config.getWorkDir()+"/run/finished"));

			
			Logger.debug("Search pax files...");
			List<String> paxList = FSOperationBase.getDirContentRecursivePax(config.getWorkDir() +"/run/finished");	
			if(paxList == null || paxList.size()==0) {
				Logger.debug("Can't find pax files - verification failed.");
				String[] dcontent = FSOperationBase.getDirs(config.getWorkDir()+"/run/work/");
				
				for(int i=0; i<dcontent.length; i++) {
					File currentBadWorkFileSrc = new File(config.getWorkDir()+"/run/work/"+dcontent[i]);
					File currentBadWorkFileDest = new File(config.getWorkDir()+"/run/errors/work/"+dcontent[i]+"_"+task.getId());
					Logger.debug("Rename \""+currentBadWorkFileSrc.getAbsolutePath()+"\" to "+
							currentBadWorkFileDest.getAbsolutePath()+"\".");
					currentBadWorkFileSrc.renameTo(currentBadWorkFileDest);
				}
				FSOperationBase.removeDirectoryRecursive(new File(config.getWorkDir()+"/run/work"));
				FSOperationBase.removeDirectoryRecursive(new File(config.getWorkDir()+"/run/finished"));
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
				" ldv_statuses=1 ldv-upload --online --no-kb "+paxFileString+" 2>&1";
				runCommand(config.getWorkDir() +"/start", startString);	
				// remove it
				Logger.debug("Delete pax file: "+paxFileString);
				(new File(paxFileString)).delete();
			}
			Logger.debug("All pax files uploaded.");
			Logger.debug("Clean node dirs...");
			FSOperationBase.removeDirectoryRecursive(new File(config.getWorkDir()+"/run/work"));
			FSOperationBase.removeDirectoryRecursive(new File(config.getWorkDir()+"/run/finished"));
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
