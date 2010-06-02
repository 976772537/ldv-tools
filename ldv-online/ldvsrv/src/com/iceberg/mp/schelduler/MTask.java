package com.iceberg.mp.schelduler;

import java.io.Serializable;

public class MTask implements Serializable {
	
	public int getId() {
		return id;
	}

	public String getVparams() {
		return vparams;
	}

	public byte[] getData() {
		return data;
	}

	private static final long serialVersionUID = 1L;
	private int id;
	private String vparams;
	private byte[] data;
	
	public MTask(Task task) {
		this.id = task.getId();
		this.data = task.getData();
		this.vparams = Task.getSerVparams(task);
	}
}
