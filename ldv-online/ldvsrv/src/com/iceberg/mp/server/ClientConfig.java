package com.iceberg.mp.server;

import java.util.Map;

public class ClientConfig extends Config {

	private String clientName;
	private String LDVInstalledDir;
	private String workDir;
	
	public ClientConfig(Map<String,String> params,ServerThreadEnum type) {
		super(params,type);
		this.clientName = params.get("ClientName");
		this.workDir = params.get("WorkDir");
		this.LDVInstalledDir = params.get("LDVInstalledDir");
	}
	
	public String getCientName() {
		return clientName;
	}
	
	public String getLDVInstalledDir() {
		return LDVInstalledDir;
	}
	
	public String getWorkDir() {
		return workDir;
	}



}
