package com.iceberg.mp.schelduler;

import java.util.List;
import java.util.Map;

import com.iceberg.mp.Logger;
import com.iceberg.mp.db.SQLRequests;
import com.iceberg.mp.db.StorageManager;

public class Scheduler extends Thread {
	
	private StorageManager sManager;
	private int timeout_for_one = 3000;
	private int trycount = 5;

	private int tryMemMonitor = 0;
	private int tryOtherCounter =  0;

	public Scheduler(Map<String, String> params, StorageManager storageManager) {
		this.sManager = storageManager;
	}

	public void timeout() {
		try {
			Thread.sleep(timeout_for_one);
		} catch (InterruptedException e) {
			e.printStackTrace();
		}		
	}
	
	// только планировщик имеет право работать с VerClient'ами
	public void run() {
		Logger.debug("SCHELDUER: Start thread.");		
		while(true) {
			// 1. ищем номера задач RTASKS в статусе WAIT_FOR_VERIFICATION...
			List<Integer> idOfWaitingTasks = SQLRequests.getSplittedTasksIdW_WAIT_FOR_VERIFICATION(sManager);
			if(idOfWaitingTasks!=null && idOfWaitingTasks.size()>0) {
				// 2. ожидаем свободных машин для верификации
				List<Integer> idOfWaitingClients = null;
				for(int i=0; i<trycount; i++) {
					idOfWaitingClients = SQLRequests.getClientsIdW_W_WAIT_FOR_TASK(sManager);
					if(idOfWaitingClients!=null && idOfWaitingClients.size()>0) {
						// распределяем все задачи равномерно или как-нибудь по-другому, не важно
						for(int j=0, k=0; j<idOfWaitingTasks.size(); j++, k++) {
							if(k>=idOfWaitingClients.size()) k=0;
							SQLRequests.setSplittedTaskToCLientW(sManager, idOfWaitingClients.get(k), idOfWaitingTasks.get(j));
						}
						break;
					} 
					timeout();
				}
			//}
			// занимаемся другими делами, т.е.
			// чистим испорченные записи и т.д.
			} else {
				// когда нет дела, просто таймаут..
				timeout();
			}
			// стандартный тайм-аут
			timeout();
			// чтобы соединения не засыпали в MySQL периодически будем 
			// их дрегать
			if(tryMemMonitor++ > 4) {
		                Logger.info("MEM: Free   memory in JVM: "+Runtime.getRuntime().freeMemory()+" bytes.");
              			Logger.info("MEM: Total Memory for JVM: "       +Runtime.getRuntime().totalMemory()+" bytes.");
				tryMemMonitor = 0;
			}

			if(tryOtherCounter  > 100) {
				SQLRequests.noSleep(sManager);
				tryOtherCounter = 0;
			}
		}
	}	
}
