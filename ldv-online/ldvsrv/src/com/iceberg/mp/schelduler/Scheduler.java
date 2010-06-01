package com.iceberg.mp.schelduler;

import java.util.List;
import java.util.Map;

import java.util.concurrent.CopyOnWriteArrayList;

import com.iceberg.mp.RunLDV;
import com.iceberg.mp.db.StorageManager;

public class Scheduler extends Thread {
	
	private StorageManager sManager;

	public Scheduler(Map<String, String> params, StorageManager storageManager) {
		this.sManager = storageManager;
	}

	// список у нас уже синхронизирован...
	public synchronized void putTask(Task task) {
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
	public synchronized void putVERClient(VerClient vclient) {
		RunLDV.log.info("SCHELDUER: Add verification client to pull.");
	}


	public synchronized VerClient getVERClient(String name) {
		//sManager.getConnection()
		return null;
	}
}
