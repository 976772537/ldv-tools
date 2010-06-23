package com.iceberg.mp.vs.client;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.FileWriter;
import java.io.IOException;
import java.util.Map;

import com.iceberg.mp.Utils;
import com.iceberg.mp.Logger;
import com.iceberg.mp.schelduler.MTask;
import com.iceberg.mp.server.ClientConfig;
import com.iceberg.mp.server.Config;
import com.iceberg.mp.server.ServerThreadEnum;

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
			} else {
				Logger.debug("Task from user: "+task.getId());
				Logger.info("Start verification...");
				String report = startVerification(config, task);
				Logger.info("Verification end.");
				Logger.debug("Try to send results...");
				if(!protocol.VSSendResults(report,task.getId())) {
					Logger.err("Can't send results...");
					System.exit(1);
				}
				Logger.info("Results successfully sending...");
			}	
			//break;
		}
	}
	
	// возвращает строку на репорт
	@SuppressWarnings("finally")
	public static String startVerification(ClientConfig config, MTask task) {
//		LDV_DEBUG=100 ldv task --driver=drivers/char/agp --workdir=. --env=vanilla@37_1 --kernel-driver > ./global.log 2>&1 & tail -f ./global.log
		// 1. сохраняем файл в wokrdir
		File tworkdir = new File(config.getWorkDir()+"/run");
		tworkdir.mkdirs();
		FileOutputStream fis = null;
		String report = null;
		try {
			fis = new FileOutputStream(config.getWorkDir()+"/driver");
			fis.write(task.getData());
			fis.flush();
			fis.close();

			report = config.getWorkDir() +"/run/ldvs_report.xml";
			File reportFile = new File(report);
			reportFile.delete();
			String startString = "cd "+ config.getWorkDir() +"/run; export PATH=$PATH:" +
					config.getLDVInstalledDir()+"/bin; LDV_DEBUG="+Logger.logLevel+" ldv task "
					+"--driver="+config.getWorkDir()+"/driver --workdir="+config.getWorkDir()+"/run " +
					" --report-out="+report+" --env="+task.getEnv()+"@"+task.getRule();
			Logger.trace("RUN LDV:" + startString);
			Logger.debug("Write start command in file :" + config.getWorkDir() +"/start");
			FileWriter startFile = new FileWriter(config.getWorkDir() +"/start");
			startFile.write(startString);
			startFile.flush();
			startFile.close();
			
			Utils.runFromFile(config.getWorkDir() +"/start");
			
			if(reportFile.exists()) {
				Logger.debug("Report created in file: " + report);
			} else {
				Logger.debug("LDV-Tools failed.");
				report = null;
			}
		} catch (FileNotFoundException e) {
			e.printStackTrace();
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} finally {
			try {
				fis.close();
			} catch (IOException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
			return report;
		}
	}
}
