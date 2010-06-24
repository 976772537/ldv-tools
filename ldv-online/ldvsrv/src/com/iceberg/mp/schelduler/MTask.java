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
	private byte[] data;
	
	public int getId() {
		return id;
	}

	public String getEnv() {
		return env;
	}
	
	public String getRule() {
		return rule;
	}

	public byte[] getData() {
		return data;
	}


	public MTask(int id, String env, String rule, byte[] data) {
		this.id = id;
		this.env = env;
		this.rule = rule;
		this.data = data;
	}
	
}
