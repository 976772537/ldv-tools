package com.iceberg.mp;

import java.util.List;
import java.util.ArrayList;


/*
 * задача должна помещаться в пул только после того как она готова,
 * т.е. класс не будет меняться
 * 
 *  - статус задачи имеет право менять только планировщик
 *  
 * 
 * 
 */

public class Task {
	
	/**
	 *	состояния в которых может находится задача
	 */
	public static enum Status {
		TS_WAIT_FOR_VERIFICATION,
		TS_VERIFICATION_FINISHED,
		TS_VERIFICATION_IN_PROGRESS
	}

	/**
	 * текущее состояние задачи
	 */
	private Status status = Status.TS_WAIT_FOR_VERIFICATION;
	
	private List<Env> envs = new ArrayList<Env>();
	private byte[] driver = null;
	private int size = 0;
	
	public Task(String task, byte[] driver) {
		int begin = task.indexOf("@");
		String ssize = task.substring(0, begin);
		String tenvs = task.substring(begin+1, task.length());
		this.envs = parseEnvs(tenvs);
		this.size = Integer.parseInt(ssize);
		this.driver = driver;
	}
	
	public int getSize() {
		return size;
	}
	
	public Status getStatus() {
		return status;
	}
	
	public void setStatus(String status) {
		
	}
	
	private static List<Env> parseEnvs(String senv) {
		List<Env> envlist = new ArrayList<Env>();
		String[] msenvs = senv.split(":");
		for(int i=0;i<msenvs.length; i++) {
			String serEnv = msenvs[i];
			Env env = Env.deserEnv(serEnv);
			envlist.add(env);
		}
		return envlist;
	}
	
	public List<Env> getEnvs() {
		return envs;
	}

	public byte[] getData() {
		return driver;
	}

	public static int getSizeFromString(String task) {
		int begin = task.indexOf("@");
		String ssize = task.substring(0, begin);		
		return Integer.valueOf(ssize);
	}
	
}	
