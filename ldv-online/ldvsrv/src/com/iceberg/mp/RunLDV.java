package com.iceberg.mp;

import java.util.logging.Logger;

import com.iceberg.mp.schelduler.Scheduler;
import com.iceberg.mp.server.Server;
import com.iceberg.mp.server.ServerConfig;
import com.iceberg.mp.server.ServerThreadEnum;

public class RunLDV {
	
	public static final Logger log=Logger.getLogger("imeo");
	
	public static void main(String[] args) {
		// создаем планировщик
		Scheduler scheduler = new Scheduler();
		// создаем конфигурацию сервера для веба
		ServerConfig wsConfig = new ServerConfig("localhost",11111,scheduler,ServerThreadEnum.WS);
		// создаем конфигурацию сервера для клиентов
		ServerConfig vsConfig = new ServerConfig("localhost",1111,scheduler,ServerThreadEnum.VS);

		// создаем сервер для веба
		Server wserver = new Server(wsConfig);
		// и сервер для клиентов
		Server vserver = new Server(vsConfig);

		log.info("Try to start schelduler...");
		scheduler.start();
		log.info("Try to start WS Server...");
		wserver.start();
		log.info("Try to start VS Server...");
		vserver.start();
		
	}
}
