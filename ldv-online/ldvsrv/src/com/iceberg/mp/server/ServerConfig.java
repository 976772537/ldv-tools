package com.iceberg.mp.server;

import java.util.Map;

import com.iceberg.mp.db.ConnectionManager;
import com.iceberg.mp.schelduler.Scheduler;

public class ServerConfig extends Config {

	private Scheduler schelduler;
	private ServerThreadEnum serverType;

	public ServerConfig(String serverName, int port, Scheduler schelduler, 
			ServerThreadEnum serverType) {
		super(serverName, port);
		this.serverType = serverType;
		this.schelduler = schelduler;
	}

	public ServerConfig(Map<String, String> params, Scheduler scheduler,
			ConnectionManager connectmanager ,ServerThreadEnum serverType) {
		if(serverType.equals(ServerThreadEnum.VS))
		super(params,String type);
		this.serverType = serverType;
		this.schelduler = schelduler;
	}

	public ServerThreadEnum getServerType() {
		return serverType;
	}

	public Scheduler getSchelduler() {
		return schelduler;
	}
}
