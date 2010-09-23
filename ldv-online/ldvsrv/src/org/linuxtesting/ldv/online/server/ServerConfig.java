package org.linuxtesting.ldv.online.server;

import java.util.Map;

import org.linuxtesting.ldv.online.db.StorageManager;
import org.linuxtesting.ldv.online.schelduler.Scheduler;

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
