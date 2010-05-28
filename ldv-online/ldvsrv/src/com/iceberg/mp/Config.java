package com.iceberg.mp;

public class Config {

	private String serverName = "localhost";
	private int wServerPort = 11111;
	private int vServerPort = 1111;
	
	private final static int blockSize = 8192;
	
	public static int getBlockSize() {
		return blockSize;
	}
	
	public Config() {
	}

	public String getServerName() {
		return serverName;
	}
	
	public int getWServerPort() {
		return wServerPort;
	}
	
	public int getVServerPort() {
		return vServerPort;
	}

	
}
