package com.iceberg.mp.server;

import java.util.Map;

public class ClientConfig extends Config {

	private String clientName;
	
	public ClientConfig(Map<String,String> params,ServerThreadEnum type) {
		super(params,type);
		this.clientName = params.get("ClientName");
	}
	
	public String getCientName() {
		return clientName;
	}

}
