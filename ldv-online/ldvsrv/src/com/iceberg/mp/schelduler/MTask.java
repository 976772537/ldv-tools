package com.iceberg.mp.schelduler;

import java.io.Serializable;

public class MTask implements Serializable {
	
	public static enum Status {
		TS_WAIT_FOR_VERIFICATION,
		TS_VERIFICATION_FINISHED,
		TS_VERIFICATION_IN_PROGRESS,
		TS_QUEUED,
		TS_VERIFICATION_FAILED
	}
	
	private static final long serialVersionUID = 1L;
	
	private int id;
	private String env;
	private String rule;
	private String driver;
	private byte[] data;
	private int parent_id;
	
	public int getId() {
		return id;
	}

	public String getEnv() {
		return env;
	}
	
	public String getRule() {
		return rule;
	}

	public int getParentId() {
		return parent_id;
	}
	
	public byte[] getData() {
		return data;
	}


	public MTask(int id, int parent_id, String env, String driver, String rule, byte[] data) {
		this.id = id;
		this.env = env;
		this.rule = rule;
		this.data = data;
		this.driver = driver;
		this.parent_id = parent_id;
	}

	public String getDriver() {
		return driver;
	}
	
}
