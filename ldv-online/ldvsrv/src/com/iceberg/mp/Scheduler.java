package com.iceberg.mp;

import java.util.List;

import java.util.concurrent.CopyOnWriteArrayList;

public class Scheduler extends Thread {
	
	private List<Task> taskList = new CopyOnWriteArrayList<Task>();
	private List<VerClient> clientList = new CopyOnWriteArrayList<VerClient>();
		
	// список у нас уже синхронизирован...
	public void putTask(Task task) {
		taskList.add(task);
		System.out.println("Add task: "+ task.getStatus());
	}

	
	// только планировщик имеет право работать с VerClient'ами
	public void run() {
		boolean state = false;
		while(true) {
			if(taskList.size()!=0 && clientList.size()!=0 && state==false) {
				System.out.println("Ok - first tasks");
				state = true;
			}
			// алгоритм планировки задач
			// 1. ищем свободные сервера
		}
	}
	
	// сделать синхронизированым
	public void putVERClient(VerClient vclient) {
		clientList.add(vclient);
		System.out.println("Add ver client from: "+ vclient.getVName());
	}
}
