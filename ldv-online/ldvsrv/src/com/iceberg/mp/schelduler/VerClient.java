package com.iceberg.mp.schelduler;

import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.List;
import java.util.concurrent.CopyOnWriteArrayList;

import com.iceberg.mp.server.ServerConfig;
import com.iceberg.mp.vs.vsm.VSMClient;
import com.iceberg.mp.vs.vsm.VSMClientSendResults;

public class VerClient extends Thread {
	
	private String name;
	private List<Task> taskList = new CopyOnWriteArrayList<Task>();
	private int id;
	
	private static enum Status {
		VS_WAIT_FOR_TASK,
		VS_HAVE_TASKS,
	}

	private volatile Status status = Status.VS_WAIT_FOR_TASK;

	public Status getStatus() {
		return status; 
	}
	
	public int getIdclient() {
		return id; 
	}
	
	public VerClient(VSMClient msg) {
		this.name = msg.getName();
	}
	
	public VerClient(VSMClient msg, int id_client) {
		this.name = msg.getName();
		this.id = id_client;
	}

	public VerClient(VSMClient vsmmsg, int id_client,
			com.iceberg.mp.schelduler.VerClient.Status status) {
		this.name = vsmmsg.getName();
		this.status = status;
		this.id = id_client;
	}
	
	public void putTask(Task task) {
		taskList.add(task);
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

	
	public static VerClient create(VSMClient vsmmsg, ServerConfig config) {
		Connection conn = null;
		VerClient vclient = null;
		Statement st = null;
		try {
			// Это все одна транзакция?? !!!!!!
			conn = config.getStorageManager().getConnection();
			st = conn.createStatement();
			ResultSet result = st.executeQuery("SELECT id FROM CLIENTS WHERE NAME='"+vsmmsg.getName()+"'");
			// если клиента такого нет, то регистрируем
			int id_client;
			if(result.getRow()==0 && !result.next()) {
				st.execute("INSERT INTO CLIENTS(name,status) VALUES(0,'"+vsmmsg.getName()+"','"+Status.VS_WAIT_FOR_TASK+"')");
				result = st.executeQuery("SELECT * FROM USERS WHERE NAME='"+vsmmsg.getName()+"'");
				result.next();
				id_client = result.getInt("id");
			} else { // иначе пытаемся достать из пула...
				id_client = result.getInt("id");
				vclient = config.getSchelduler().getVERClient(id_client);
				// если он есть в пуле, то возвращаем,
				// инчае еще положим его в пул
				if(vclient!=null) {
					result.close();
					return vclient;
				}
			}
			result.close();
			vclient = new VerClient(vsmmsg,id_client);
			config.getSchelduler().putVERClient(vclient);
		} catch(SQLException e) {
			e.printStackTrace();
		} finally {
			try {
				st.close();
				conn.close();
			} catch (SQLException e) {
				e.printStackTrace();
			}
		}
		return vclient;
	}

	public void resetAllPrepareStatuses() {
		for(int i=0; i<taskList.size(); i++) {
			taskList.get(0).setResetPrepareStatus();
		}
	}
	
	public Task getTask() {
		Task task = null;
		if(taskList.size()>0) {
			for(int i=0; i<taskList.size(); i++) {
				if(taskList.get(i).setPrepareForSendingToVerification())
					return taskList.get(i);		
			}
		}
		return task;
	}

	public boolean sendResults(VSMClientSendResults msg) {
		return false;
	}
}	
