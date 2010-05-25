package com.iceberg.mp;

import java.util.List;

import java.util.concurrent.CopyOnWriteArrayList;

public class Scheduler extends Thread {
	
	private List<Task> taskList = new CopyOnWriteArrayList<Task>();
	private List<VerClient> clientList = new CopyOnWriteArrayList<VerClient>();
		
	// список у нас уже синхронизирован...
	public void putTask(Task task) {
		taskList.add(task);
	}

	
	// только планировщик имеет право работать с VerClient'ами
	public void run() {
		while(true) {
			// алгоритм планировки задач
			// 1. ищем свободные сервера
		}
	}
	
	public synchronized void putVERClient(VerClient vclient) {
		clientList.add(vclient);
	}
}
