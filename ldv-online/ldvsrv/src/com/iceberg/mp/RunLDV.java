package com.iceberg.mp;

import java.util.Map;
import java.util.logging.Logger;

import com.iceberg.mp.db.ConnectionManager;
import com.iceberg.mp.schelduler.Scheduler;
import com.iceberg.mp.server.Config;
import com.iceberg.mp.server.Server;
import com.iceberg.mp.server.ServerConfig;
import com.iceberg.mp.server.ServerThreadEnum;

public class RunLDV {
	
	public static final Logger log=Logger.getLogger("imeo");
	
	public static void main(String[] args) {
		if(args.length!=1) {
			System.out.println("USAGE: java -ea -jar ldvs.jar server.conf");
			System.exit(1);
		}
		Map<String,String> params = Config.readParameters(args[0]);
		// создаем менеджер коннектов
		ConnectionManager connectManager = new ConnectionManager(params);
		// создаем планировщик
		Scheduler scheduler = new Scheduler(params);
		// создаем конфигурацию сервера для веба
		ServerConfig wsConfig = new ServerConfig(params,scheduler,connectManager,ServerThreadEnum.WS);
		// создаем конфигурацию сервера для клиентов
		ServerConfig vsConfig = new ServerConfig(params,scheduler,connectManager,ServerThreadEnum.VS);

		// создаем сервер для веба
		Server wserver = new Server(wsConfig);
		// и сервер для клиентов
		Server vserver = new Server(vsConfig);
		
		log.info("Try to init connectManager...");
		connectManager.init();		
		log.info("Try to start schelduler...");
		scheduler.start();
		log.info("Try to start WS Server...");
		wserver.start();
		log.info("Try to start VS Server...");
		vserver.start();
		
	}
}
