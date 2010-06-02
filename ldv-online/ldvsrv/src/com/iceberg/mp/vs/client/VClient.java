package com.iceberg.mp.vs.client;

import com.iceberg.mp.schelduler.Task;
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
			Task task = protocol.VSGetTask();
			if(task == null) {
				System.out.println("Can't get task...");
				System.exit(1);
			} else {
				System.out.println("Task from user: "+task.getUser());
				System.out.println("Start verification...");
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
}
