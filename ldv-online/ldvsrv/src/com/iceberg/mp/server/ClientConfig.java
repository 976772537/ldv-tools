package com.iceberg.mp.server;

import java.util.Map;

public class ClientConfig extends Config {

	private String LDVInstalledDir;
	private String workDir;
	
	private String statsDbuser;
	private String statsDbpass;
	private String statsDbhost;
	private String statsDbname;
	private String statsDbport;
	
	public ClientConfig(Map<String,String> params,ServerThreadEnum type) {
		super(params,type);
		this.workDir = params.get("WorkDir");
		this.LDVInstalledDir = params.get("LDVInstalledDir");
		// TODO: add test for params
		this.statsDbhost = params.get("StatsDBHost");
		this.statsDbname = params.get("StatsDBName");
		this.statsDbuser = params.get("StatsDBUser");
		this.statsDbpass = params.get("StatsDBPass");
		this.statsDbport = params.get("StatsDBPort");
	}
	
	public String getLDVInstalledDir() {
		return LDVInstalledDir;
	}
	
	public String getWorkDir() {
		return workDir;
	}

	public String getStatsDBHost() {
		return statsDbhost;
	}
	
	public String getStatsDBName() {
		return statsDbname;
	}
	
	public String getStatsDBUser() {
		return statsDbuser;
	}
	
	public String getStatsDBPort() {
		return statsDbport;
	}
	
	public String getStatsDBPass() {
		return statsDbpass;
	}


}
