package com.iceberg.mp.schelduler;

import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.Serializable;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;

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
		TS_PREPARE_FOR_SENDING_TO_VERIFICATION,
		TS_DIVIDED
	}
	
	public Status status = Status.TS_WAIT_FOR_VERIFICATION;
	
	private List<Env> envs;
	private byte[] driver;
	private long size;
	private String user;
	
	private String path;
	
	private int id_parent = -1;
	private int userId;
	private int Id;
	
	//public Task(byte[] driver, WSMWsmtoldvsTaskPutRequest wsm, int userId, int Id) {
		//this.driver = driver;
	public Task(WSMWsmtoldvsTaskPutRequest wsm, int userId, int Id, String path) {
		this.envs = wsm.getEnvs();
		this.size = wsm.getSourceLen();
		this.user = wsm.getUser();
		this.userId = userId;
		this.Id = Id;
		this.path = path;
	}
	
	//public Task( WSMWsmtoldvsTaskPutRequest wsm, int userId, int Id, int id_parent) {
		//this.driver = driver;
	public Task( WSMWsmtoldvsTaskPutRequest wsm, int userId, int Id, int id_parent, String path) {
		this.envs = wsm.getEnvs();
		this.size = wsm.getSourceLen();
		this.user = wsm.getUser();
		this.userId = userId;
		this.Id = Id;
		this.id_parent = id_parent;
		this.path = path;
	}
	
	public Task(int id_task,String user , int id_user, long size, List<Env> envs,
			String path, Task.Status status) {
			this.envs = envs;
			this.size = 0;
			this.user = user;
			this.userId = id_user;
			this.Id = id_task;
			this.id_parent = -1;
			this.path = path;
			this.status = status;
	}

	public VerClient getParent(Scheduler schelduler) {
		if(id_parent == -1) return null;
		return schelduler.getVERClient(id_parent);
	}
	
	public long getSize() {
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
			if(this.status==Status.TS_WAIT_FOR_VERIFICATION) 
				return this.status;
			return null;
		} else if(operation == 3) {
			if(this.status==Status.TS_PREPARE_FOR_SENDING_TO_VERIFICATION) {
				status = Status.TS_WAIT_FOR_VERIFICATION;
				driver = null;
			}
		} else if(operation == 4) {
			if(this.status==Status.TS_WAIT_FOR_VERIFICATION) {
				status = Status.TS_PREPARE_FOR_SENDING_TO_VERIFICATION;
				try {
					prepareForSending();
				} catch (FileNotFoundException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				} finally {
					// поставить стату - BAD_TASK, чтобы планировщик ее удалил
					status = Status.TS_WAIT_FOR_VERIFICATION;
				}
			}
		} else if(operation == 5) {
			if(this.status==Status.TS_PREPARE_FOR_SENDING_TO_VERIFICATION) {
				status = Status.TS_VERIFICATION_IN_PROGRESS;
				driver = null;
			}
		} else if(operation == 6) {
			if(this.status==Status.TS_VERIFICATION_IN_PROGRESS) {
				status = Status.TS_WAIT_FOR_VERIFICATION;
				driver = null;
			}
		} else if(operation == 7) {
			if(this.status==Status.TS_WAIT_FOR_VERIFICATION) {
				status = Status.TS_DIVIDED;
				driver = null;
			}
		} else if(operation == 8) {
			if(this.status==Status.TS_DIVIDED) {
				// только finished заносятся в бд
				status = Status.TS_VERIFICATION_FINISHED;
				driver = null;
			}
		}
		return this.status;
	}
	
	public void setStatus(Status status) {
		rwStatus(1,status);
	}
	
	public List<Env> getEnvs() {
		return envs;
	}

	public void prepareForSending() throws FileNotFoundException {
		if(driver != null) 
			return;
		FileInputStream fis = null;
		fis = new FileInputStream(path);
		driver = new byte[(int)size];
		try {
			fis.read(driver);
		} catch (IOException e) {
			e.printStackTrace();
		} finally {
			try {
				fis.close();
			} catch (IOException e) {
				e.printStackTrace();
			}
		}
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
		Statement st = null;
		try {
			// Это все одна транзакция?? !!!!!!
			conn = config.getStorageManager().getConnection();
			st = conn.createStatement();
			ResultSet result = st.executeQuery("SELECT id FROM USERS WHERE NAME='"+wsmMsg.getUser()+"'");
			// если пользователя такого нет, то регистрируем
			if(result.getRow()==0 && !result.next()) {
				st.execute("INSERT INTO USERS(privileges,name) VALUES(0,'"+wsmMsg.getUser()+"')");
				result = st.executeQuery("SELECT id FROM USERS WHERE NAME='"+wsmMsg.getUser()+"'");
				result.next();
			}
			int id_user = result.getInt("id");
			result.close();
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
			result.close();
			String path = config.getStorageManager().getBins()+"/"+id_task;
			FileOutputStream filebin = new FileOutputStream(config.getStorageManager().getBins()+"/"+id_task);
			filebin.write(block);
			filebin.flush();
			filebin.close();
			st.executeUpdate("INSERT INTO TASKS(id,id_user,vparams,status) VALUES("
					+id_task+","+id_user+",'" + vparams + "','"+Status.TS_WAIT_FOR_VERIFICATION+"')");
			task = new Task(wsmMsg, id_user, id_task, path);
			config.getSchelduler().putTask(task);
		} catch(SQLException e) {
			e.printStackTrace();
		} catch (FileNotFoundException e) {
			e.printStackTrace();
		} catch (IOException e) {
			e.printStackTrace();
		} finally {
			try {
				st.close();
				conn.close();
			} catch (SQLException e) {
				e.printStackTrace();
			}
		}
		return task;
	}

	public boolean setPrepareForSendingToVerification() {
		if(rwStatus(4, null) == Status.TS_PREPARE_FOR_SENDING_TO_VERIFICATION)
				return true;
		return false;
	}
	
	public void setResetPrepareStatus() {
		rwStatus(3, null);
	}
	
	public void setResetVerificationInProgressStatus() {
		rwStatus(6, null);
	}
	
	public String getPath() {
		return this.path;
	}

	public boolean setVerificationInProgress() {
		if(rwStatus(5, null) == Status.TS_VERIFICATION_IN_PROGRESS)
			return true;
		return false;
	}

	public static List<Env> getEnvsFromString(String vparams) {
		String[] senvs = vparams.split("@");
		List<Env> envList = new ArrayList<Env>();
		for(String senv : senvs) {
			String[] srules = senv.split(":");
			String name = srules[0];
			List<String> ruleList = new ArrayList<String>();
			for(int i =1; i<srules.length; i++) {
				ruleList.add(srules[i]);
			}
			envList.add(new Env(ruleList,name));
		}
		return envList;
	}

	public static List<Task> divideByEnvironment(Task task) {
		task.setDivided();
		if(task.getStatus()==Task.Status.TS_DIVIDED) {
			List<Env> envs = task.getEnvs();
			List<Task> mtList = new ArrayList<Task>();
			for(int i=0; i<envs.size(); i++) {
				// 	номер минизадачи рассчитывается как номер 
				// 	окружения родительской задачи
				List<Env> oneList = new ArrayList<Env>();
				oneList.add(envs.get(i));
				Task mttask = new Task(i,task.getUser(),task.getUserId(),task.getSize(),oneList,task.getPath(),Task.Status.TS_WAIT_FOR_VERIFICATION);
			}
			return mtList;
		}
		return null;
	}

	public Status setDivided() {
		return rwStatus(7, null);
	}
	
	public Status setFinishedFromDivided() {
		return rwStatus(8, null);
	}

}	
