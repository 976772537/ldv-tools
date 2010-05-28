package com.iceberg.mp;

import java.util.logging.Logger;

import com.iceberg.mp.vs.VServer;
import com.iceberg.mp.ws.WServer;

public class RunLDV {
	
	public static final Logger log=Logger.getLogger("imeo");
	
	public static void main(String[] args) {
		// создаем планировщик

		Scheduler scheduler = new Scheduler();
		// создаем сервер для веба

		WServer wserver = new WServer(scheduler);
		// и сервер для клиентов

//		VServer vserver = new VServer(scheduler);

		log.info("Try to start schelduler...");
		scheduler.start();
		log.info("Try to start WS Server...");
		wserver.start();
		//log.info("Try to start VS Server...");
		//vserver.start();
		
	}
}
