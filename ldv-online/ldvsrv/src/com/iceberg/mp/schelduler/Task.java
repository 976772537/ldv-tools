package com.iceberg.mp.schelduler;

import java.io.Serializable;
import java.util.List;

import com.iceberg.mp.ws.wsm.WSMWsmtoldvsTaskPutRequest;

/*
 * задача должна помещаться в пул только после того как она готова,
 * т.е. класс не будет меняться, кроме статуса...
 * 
 *  - статус задачи имеет право менять только планировщик
 * 
 */
public class Task implements Serializable {
	
	private static final long serialVersionUID = 1L;

	public static enum Status {
		TS_WAIT_FOR_VERIFICATION,
		TS_VERIFICATION_FINISHED,
		TS_VERIFICATION_IN_PROGRESS,
		TS_PREPARE_FOR_SENDING_TO_VERIFICATION
	}

	public Status status = Status.TS_WAIT_FOR_VERIFICATION;
	
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
		return rwStatus(0,null);
	}
	
	public synchronized Status rwStatus(int operation, Status status) {
		if(operation == 1) {
			this.status = status;
		} else if(operation == 2) {
			if(status==Status.TS_WAIT_FOR_VERIFICATION) 
				return this.status;
			return null;
		}
		return this.status;
	}
	
	public void setStatus(Status status) {
		rwStatus(1,status);
	}
	
	public List<Env> getEnvs() {
		return envs;
	}

	public byte[] getData() {
		return driver;
	}

	public Status getStatusForSending() {
		return rwStatus(3, null);
	}
}	
