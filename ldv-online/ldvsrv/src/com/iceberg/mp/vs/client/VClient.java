package com.iceberg.mp.vs.client;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;

import com.iceberg.mp.RunLDV;
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
		ClientConfig config = new ClientConfig(Config.readParameters(args[0]), ServerThreadEnum.VS);
		VClientProtocol protocol = new VClientProtocol(config);
		while(true) {
			MTask task = protocol.VSGetTask();
			if(task == null) {
				System.out.println("Can't get task...");
				System.exit(1);
			} else {
				System.out.println("Task from user: "+task.getId());
				System.out.println("Start verification...");
				String report = startVerification(config, task);
				System.out.println("Ok.");
				System.out.println("Try to send results...");
				if(!protocol.VSSendResults()) {
					System.out.println("Can't send results...");
					System.exit(1);
				}
				System.out.println("Results successfully sending...");
			}	
		}
	}
	
	// возвращает строку на репорт
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
					config.getLDVInstalledDir()+"/bin; ldv task "
					+"--driver="+config.getWorkDir()+"/driver --workdir="+config.getWorkDir()+"/run " +
					" --report-out="+report+" --env="+task.getVparams();
			RunLDV.log.info("RUN LDV:" + startString);

			FileWriter startFile = new FileWriter(config.getWorkDir() +"/start");
			startFile.write(startString);
			startFile.flush();
			startFile.close();
			
			try {
				Process proc = Runtime.getRuntime().exec("bash "+config.getWorkDir() +"/run/start && exit;");
				BufferedReader br = new BufferedReader(new InputStreamReader(proc.getInputStream()));
				String line = null;
				while ((line = br.readLine()) != null) { 
					System.out.println(line); 
			    }
				proc.waitFor();
			} catch (IOException e) {
				e.printStackTrace();
			} catch (InterruptedException e) {
				/*String[] commands = startString.split(" ");
				Process proc = Runtime.getRuntime().exec(commands);
				System.setIn(proc.getInputStream());*/ 
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
			
			if(reportFile.exists()) {
				RunLDV.log.info("Report created in file: " + report);
			} else {
				RunLDV.log.info("LDV-Tools failed.");
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
			report = null;
		}
		return report;
	}
}
