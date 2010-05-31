package com.iceberg.mp.server;

public class ClientConfig extends Config {

	private String clientName;
	
	public ClientConfig(String serverName, int port, String clientName) {
		super(serverName, port);
		this.clientName = clientName;
	}
	
	public String getCientName() {
		return clientName;
	}

}
