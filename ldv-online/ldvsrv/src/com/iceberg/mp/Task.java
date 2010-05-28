package com.iceberg.mp;

import java.util.List;

import com.iceberg.mp.ws.wsm.WSMWsmtoldvsTaskPutRequest;

/*
 * задача должна помещаться в пул только после того как она готова,
 * т.е. класс не будет меняться, кроме статуса...
 * 
 *  - статус задачи имеет право менять только планировщик
 * 
 */
public class Task {
	
	public static enum Status {
		TS_WAIT_FOR_VERIFICATION,
		TS_VERIFICATION_FINISHED,
		TS_VERIFICATION_IN_PROGRESS
	}

	private Status status = Status.TS_WAIT_FOR_VERIFICATION;
	
	private List<Env> envs;
	private byte[] driver;
	private int size;
	private String user;
	
	public Task(byte[] driver, WSMWsmtoldvsTaskPutRequest wsm) {
		this.driver = driver;
		this.envs = wsm.getEnvs();
		this.size = wsm.getSourceLen();
		this.user = wsm.getUser();
	}
	
	public int getSize() {
		return size;
	}
	
	public String getUser() {
		return user;
	}
	
	public Status getStatus() {
		return status;
	}
	
	public void setStatus(String status) {
		// synchronized must be
	}

	public List<Env> getEnvs() {
		return envs;
	}

	public byte[] getData() {
		return driver;
	}
}	
