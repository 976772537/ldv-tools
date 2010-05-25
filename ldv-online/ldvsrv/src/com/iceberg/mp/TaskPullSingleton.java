package com.iceberg.mp;

import java.util.Collections;
import java.util.List;
import java.util.ArrayList;

import java.util.concurrent.CopyOnWriteArrayList;

public class TaskPullSingleton {
	
	private static volatile TaskPullSingleton instance;
	
	private TaskPullSingleton() {
		
	}
	
	public static TaskPullSingleton getInstance() {
			if(instance == null) 
				synchronized (TaskPullSingleton.class) {
					if(instance == null)
						instance = new TaskPullSingleton();
				}
			return instance;
	}
	
	private List<Task> taskList = new CopyOnWriteArrayList<Task>();
		
	public synchronized void putTask(Task task) {
		taskList.add(task);
	}
	
	/*public synchronized void getTask() {
		taskList.get();
	}*/
}
