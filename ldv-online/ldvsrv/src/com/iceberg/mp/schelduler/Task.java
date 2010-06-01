package com.iceberg.mp.schelduler;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.FileWriter;
import java.io.IOException;
import java.io.Serializable;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.List;

import com.iceberg.mp.db.StorageManager;
import com.iceberg.mp.server.ServerConfig;
import com.iceberg.mp.ws.wsm.WSMWsmtoldvsTaskPutRequest;

/*
 * задача должна помещаться в пул только после того как она готова,
 * т.е. класс не будет меняться, кроме статуса...
 * 
 *  - статус задачи имеет право менять только планировщик
 * 
 */
public class Task implements Serializable {
	
	private static final long serialVersionUID = 1L;

	public static enum Status {
		TS_WAIT_FOR_VERIFICATION,
		TS_VERIFICATION_FINISHED,
		TS_VERIFICATION_IN_PROGRESS,
		TS_PREPARE_FOR_SENDING_TO_VERIFICATION
	}

	public Status status = Status.TS_WAIT_FOR_VERIFICATION;
	
	private List<Env> envs;
	private byte[] driver;
	private int size;
	private String user;
	
	private int userId;
	private int Id;
	
	public Task(byte[] driver, WSMWsmtoldvsTaskPutRequest wsm, int userId, int Id) {
		this.driver = driver;
		this.envs = wsm.getEnvs();
		this.size = wsm.getSourceLen();
		this.user = wsm.getUser();
		this.userId = userId;
		this.Id = Id;
	}
	
	public int getSize() {
		return size;
	}
	
	public String getUser() {
		return user;
	}
	
	public int getUserId() {
		return userId; 
	}
	
	public Status getStatus() {
		return rwStatus(0,null);
	}
	
	public synchronized Status rwStatus(int operation, Status status) {
		if(operation == 1) {
			this.status = status;
		} else if(operation == 2) {
			if(status==Status.TS_WAIT_FOR_VERIFICATION) 
				return this.status;
			return null;
		}
		return this.status;
	}
	
	public void setStatus(Status status) {
		rwStatus(1,status);
	}
	
	public List<Env> getEnvs() {
		return envs;
	}

	public byte[] getData() {
		return driver;
	}

	public Status getStatusForSending() {
		return rwStatus(3, null);
	}

	public static Task create(byte[] block, WSMWsmtoldvsTaskPutRequest wsmMsg, ServerConfig config) {
		Connection conn = null;
		Task task = null;
		try {
			// Это все одна транзакция?? !!!!!!
			conn = config.getStorageManager().getConnection();
			Statement st = conn.createStatement();
			ResultSet result = st.executeQuery("SELECT id FROM USERS WHERE NAME='"+wsmMsg.getUser()+"'");
			// если пользователя такого нет, то регистрируем
			if(result.getRow()==0 && !result.next()) {
				st.execute("INSERT INTO USERS(privileges,name) VALUES(0,'"+wsmMsg.getUser()+"')");
				//conn.commit();
				//conn.close();
				result = st.executeQuery("SELECT * FROM USERS"); //WHERE NAME='"+wsmMsg.getUser()+"'");
				result.next();
			}
			int id_user = result.getInt("id");
			// теперь вставляем задачу
			String vparams = "";
			for(Env env : wsmMsg.getEnvs()) {
				vparams+="@"+env.getName();
				for(String rule: env.getRules())
					vparams+=":"+rule;
			}
			// БЛОКИРОВАТЬ ТАБЛИЦУ ЗАДАЧ или синхронизировать этот блок кода??!!!!!!
			// Задачи не должны добавляться одновременно!!!
			// иначе будет проблема с индексом!!!
			int id_task;
			result = st.executeQuery("SELECT MAX(id) FROM TASKS");
			if(result.getRow()==0 && !result.next())
				id_task = 1;	
			else
				id_task = result.getInt(1)+1;
			FileOutputStream filebin = new FileOutputStream(config.getStorageManager().getBins()+"/"+id_task);
			filebin.write(block);
			filebin.flush();
			filebin.close();
			st.executeUpdate("INSERT INTO TASKS(id,id_user,vparams,status) VALUES("
					+id_task+","+id_user+",'" + vparams + "','"+Status.TS_WAIT_FOR_VERIFICATION+"')");
			task = new Task(block, wsmMsg, id_user, id_task);
			config.getSchelduler().putTask(task);
		} catch(SQLException e) {
			e.printStackTrace();
		} catch (FileNotFoundException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} finally {
			try {
				conn.close();
			} catch (SQLException e) {
				e.printStackTrace();
			}
		}
		return task;
	}
}	
