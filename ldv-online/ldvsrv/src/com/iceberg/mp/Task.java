package com.iceberg.mp;

import java.util.List;
import java.util.ArrayList;

public class Task {
	private List<Env> envs = new ArrayList<Env>();
	
	private byte[] driver = null;
	private int size = 0;
	
	public Task(List<Env> envlist, int size) {
		envs = envlist;
		this.size = size;
	}
	
	public int getSize() {
		return size;
	}
	
	public static Task deserTask(String task) {
		int begin = task.indexOf("@");
		String ssize = task.substring(0, begin);
		String tenvs = task.substring(begin+1, task.length());
		List<Env> envList = parseEnvs(tenvs);
		return new Task(envList, Integer.parseInt(ssize));
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
	

	public void setData(byte[] block) {
		this.driver = block;
	}
}	
