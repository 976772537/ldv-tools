package com.iceberg.mp.server;

import java.util.Map;

import com.iceberg.mp.db.StorageManager;
import com.iceberg.mp.schelduler.Scheduler;

public class ServerConfig extends Config {

	private Scheduler schelduler;
	private ServerThreadEnum serverType;
	private StorageManager storageManager;

	public ServerConfig(Map<String, String> params, Scheduler scheduler,
			StorageManager storageManager ,ServerThreadEnum serverType) {
		super(params, serverType);
		this.serverType = serverType;
		this.schelduler = scheduler;
		this.storageManager = storageManager;
	}

	public ServerThreadEnum getServerType() {
		return serverType;
	}
	
	public StorageManager getStorageManager() {
		return storageManager;
	}

	public Scheduler getSchelduler() {
		return schelduler;
	}
}
