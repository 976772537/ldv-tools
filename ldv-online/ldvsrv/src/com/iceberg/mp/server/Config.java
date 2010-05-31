package com.iceberg.mp.server;

public class Config {

	private String serverName;
	private int serverPort;

	public Config(String serverName, int port) {
		this.serverName = serverName;
		this.serverPort = port;
	}
	
	public String getServerName() {
		return serverName;
	}
	
	public int getServerPort() {
		return serverPort;
	}
	
}
