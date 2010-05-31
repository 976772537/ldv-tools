package com.iceberg.mp.server;

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

	public ServerThreadEnum getServerType() {
		return serverType;
	}

	public Scheduler getSchelduler() {
		return schelduler;
	}
}
