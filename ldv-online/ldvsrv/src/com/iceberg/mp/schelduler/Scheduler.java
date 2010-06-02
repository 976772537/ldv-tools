package com.iceberg.mp.schelduler;

import java.io.File;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.List;
import java.util.Map;

import java.util.concurrent.CopyOnWriteArrayList;

import com.iceberg.mp.RunLDV;
import com.iceberg.mp.db.StorageManager;
import com.iceberg.mp.server.ClientConfig;

public class Scheduler extends Thread {
	
	private StorageManager sManager;

	// список полноценных задач
	private List<Task> btList = new CopyOnWriteArrayList<Task>();
	// список клиентов
	private List<VerClient> vcList = new CopyOnWriteArrayList<VerClient>();
	
	public Scheduler(Map<String, String> params, StorageManager storageManager) {
		this.sManager = storageManager;
	}

	public boolean init() {
		// надо подгрузить все задачи из БД, со статусами....
		// и, возможно клиентов
		Connection conn = null;
		Statement st = null;
		try {
			conn = sManager.getConnection();
		} catch (SQLException e) {
			e.printStackTrace();
			return false;
		}  
		try {
			st = conn.createStatement();
		} catch (SQLException e) {
			e.printStackTrace();
			try {
				conn.close();
			} catch (SQLException e1) {
				// TODO Auto-generated catch block
				e1.printStackTrace();
			}
			return false;
		}
		
		try {
			ResultSet rs = st.executeQuery("SELECT * FROM TASKS WHERE status='"+Task.Status.TS_WAIT_FOR_VERIFICATION+"'");
			while(rs.next()) {
				int id_task = rs.getInt("id");
				int id_user = rs.getInt("id");
				String vparams = rs.getString("vparams");
				String sstatus = rs.getString("status");
				Task.Status status = Enum.valueOf(Task.Status.class, sstatus);
				String path = sManager.getBins()+"/"+id_task;
				File file = new File(path);
				rs.close();
				rs = st.executeQuery("SELECT name FROM USERS WHERE id="+id_user);
				rs.next();
				String username = rs.getString("name");
				Task task = new Task(id_task,username,id_user,file.length(),Task.getEnvsFromString(vparams),path,status);
				btList.add(task);		
			}
			// + очистить таблицу с клиентами
			// + сбросить статусы у задач IN_PROGRESS,IN_PREPARE и т.д.,
			//   кроме WAIT_FOR_VERIFICATION и VERIFICATION_FINISHED
			rs.close();
		} catch (SQLException e) {
			e.printStackTrace();
			try {
				st.close();
			} catch (SQLException e2) {
				e2.printStackTrace();
			} finally {
				try {
					conn.close();
				} catch (SQLException e1) {
					e1.printStackTrace();
				}
			}
		}	
		return true;
	}
	
	private int timeout_for_one = 5000;
	
	// список у нас уже синхронизирован...
	public synchronized void putTask(Task task) {
		RunLDV.log.info("SCHELDUER: Add task to pull...");
		btList.add(task);
		RunLDV.log.info("SCHELDUER: Ok");
	}

	// только планировщик имеет право работать с VerClient'ами
	public void run() {
		RunLDV.log.info("SCHELDUER: Start thread.");		
		while(true) {
			// 1. ищем задачи для верификации
			if(btList.size()>0) {
				for(int i=0; i<btList.size(); i++) {
					Task task = btList.get(i);
					if(task.getStatus().equals(Task.Status.TS_WAIT_FOR_VERIFICATION)) {
						List<Task> taskList = Task.divideByEnvironment(task);
						if(taskList!=null) {
						// ожидаем клиентов для верификации
							while(vcList.size()==0) try { Thread.sleep(timeout_for_one);} catch (InterruptedException e) {};
							// ок, теперь расфасовываем минизадачи по клиентам
							int j=0;
							for(Task mtask : taskList) {
								if(j>=vcList.size()) j=0;
								vcList.get(j).putTask(mtask);
								j++;
							}
						}
					} else if(task.getStatus().equals(Task.Status.TS_VERIFICATION_FINISHED)) {
						
					}
				}
			} 
			
			if(vcList.size() == 0 && btList.size()==0) {
				try {Thread.sleep(timeout_for_one);} catch (InterruptedException e) {}
			}
			// берем задачу и разбиваем ее на множество дочерних...
			List<Task> mtList = Task.divideByEnvironment(btList.get(0));
			// раздаем клиентам в пулы
			
		}
	}
	
	// сделать синхронизированым
	public synchronized void putVERClient(VerClient vclient) {
		RunLDV.log.info("SCHELDUER: Add client to pull...");
		vcList.add(vclient);
		RunLDV.log.info("SCHELDUER: Ok");
	}

	public synchronized VerClient getVERClient(int id_client) {
		for(int i=0; i<vcList.size(); i++) 
			if(vcList.get(i).getIdclient() == id_client)
				return vcList.get(i); 
		return null;
	}
}
