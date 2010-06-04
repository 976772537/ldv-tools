package com.iceberg.mp;

import java.io.IOException;
import java.sql.SQLException;
import java.util.Map;

import com.iceberg.mp.db.StorageManager;
import com.iceberg.mp.schelduler.Scheduler;
import com.iceberg.mp.Logger;
import com.iceberg.mp.server.Config;
import com.iceberg.mp.server.Server;
import com.iceberg.mp.server.ServerConfig;
import com.iceberg.mp.server.ServerThreadEnum;

public class RunLDV {
	
	//public static final Logger log=Logger.getLogger("imeo");
	
	public static void main(String[] args) throws IOException, SQLException, ClassNotFoundException {
		if(args.length!=1) {
			Logger.norm("USAGE: java -ea -jar ldvs.jar server.conf");
			System.exit(1);
		}
		
		// прочитаем параметры
		Map<String,String> params = Config.readParameters(args[0]);
		// настроим логгер
		Logger.getLogLevelFromMap(params);
		// выведем информацию о памяти
		Logger.info("Free memory in system: "+Runtime.getRuntime().freeMemory());
		Logger.info("Memory for JVM: "+Runtime.getRuntime().totalMemory()+"");
		
		// создаем менеджер коннектов
		StorageManager storageManager = new StorageManager(params);
		// создаем планировщик
		Scheduler scheduler = new Scheduler(params, storageManager);
		// создаем конфигурацию сервера для веба
		ServerConfig wsConfig = new ServerConfig(params,scheduler,storageManager,ServerThreadEnum.WS);
		// создаем конфигурацию сервера для клиентов
		ServerConfig vsConfig = new ServerConfig(params,scheduler,storageManager,ServerThreadEnum.VS);

		// создаем сервер для веба
		Server wserver = new Server(wsConfig);
		// и сервер для клиентов
		Server vserver = new Server(vsConfig);
		
		Logger.info("Init connectManager...");
		storageManager.init();
		Logger.info("ConnectManager successfully initialized.");
		Logger.info("Initializing schelduler...");
		scheduler.init();
		Logger.info("Schelduler successfully initialized.");
		Logger.info("Starting schelduler...");
		scheduler.start();
		Logger.info("Schelduler successfully started.");
		Logger.info("Starting WS server (it support PHP API from web-face)...");
		wserver.start();
		Logger.info("wS server successfully started.");
		Logger.info("Starting VS server (it support verification machines)...");
		vserver.start();
		Logger.info("VS server successfully started.");
		Logger.norm("All services started.");
	}
}
