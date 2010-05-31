package com.iceberg.mp.schelduler;

import java.util.List;
import java.util.concurrent.CopyOnWriteArrayList;

import com.iceberg.mp.vs.vsm.VSMClient;

public class VerClient extends Thread {
	
	private String name;
	private List<Task> taskList = new CopyOnWriteArrayList<Task>();
	
	private static enum Status {
		VS_WAIT_FOR_TASK,
		VS_HAVE_TASKS,
	}

	private volatile Status status = Status.VS_WAIT_FOR_TASK;

	public Status getStatus() {
		return status; 
	}
	
	public VerClient(VSMClient msg) {
		this.name = msg.getName();
	}

	public String getVName() {
		return name;
	}

	public Task getTaskForSending() {
		// ищем задачу в статусе prepared
		for(int i=0; i<taskList.size(); i++) {
			if(taskList.get(i).getStatusForSending()!=null)
				return taskList.get(i);
		}
		return null;
	}
}	
