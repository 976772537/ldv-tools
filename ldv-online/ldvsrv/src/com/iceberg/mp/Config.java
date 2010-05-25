package com.iceberg.mp;

public class Config {

	private String serverName = "localhost";
	private int serverPort = 11111;
	private int pserverPort = 1111;
	
	
	public Config() {
	}

	public String getServerName() {
		return serverName;
	}
	
	public int getServerPort() {
		return serverPort;
	}
	
	public int getPServerPort() {
		return pserverPort;
	}

	
}
