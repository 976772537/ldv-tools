package com.iceberg.mp.vs.client;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;

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
				startVerification(config, task);
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
		try {
			fis = new FileOutputStream(config.getWorkDir()+"/driver");
			fis.write(task.getData());
			fis.flush();
			fis.close();

			String startString = "cd "+ config.getWorkDir() +"/run; export PATH=$PATH:" +
					config.getLDVInstalledDir()+"/bin; ldv task "
					+"--driver="+config.getWorkDir()+"/driver --workdir="+config.getWorkDir()+"/run --env="+
					task.getVparams();
			System.out.println("DEBUG:" + startString);
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
		}
		return null;
	}
}
