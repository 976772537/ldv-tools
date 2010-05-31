package com.iceberg.mp.schelduler;

import java.util.List;

import java.util.concurrent.CopyOnWriteArrayList;

import com.iceberg.mp.RunLDV;

public class Scheduler extends Thread {
	
	private List<Task> taskList = new CopyOnWriteArrayList<Task>();
	private List<VerClient> clientList = new CopyOnWriteArrayList<VerClient>();
		
	// список у нас уже синхронизирован...
	public void putTask(Task task) {
		taskList.add(task);
		RunLDV.log.info("SCHELDUER: Add task to pull.");
	}

	// только планировщик имеет право работать с VerClient'ами
	public void run() {
		RunLDV.log.info("SCHELDUER: Start thread.");
		while(true) {
			//for(VerClient vclient :clientList) {
				
			//}
			// ищем задачу,
			// ищем подходящего клиента
			// пишем задачу ему в поток
			// анализируем чужие потоки, разгружаем если необходимо
		}
		//RunLDV.log.info("SCHELDUER: End thread.");
	}
	
	// сделать синхронизированым
	public void putVERClient(VerClient vclient) {
		clientList.add(vclient);
		RunLDV.log.info("SCHELDUER: Add verification client to pull.");
	}


	public VerClient getVERClient(String name) {
		for(int i=0; i<clientList.size(); i++) {
			if(clientList.get(i).getVName().equals(name))
				return clientList.get(i);
		}
		return null;
	}
}
