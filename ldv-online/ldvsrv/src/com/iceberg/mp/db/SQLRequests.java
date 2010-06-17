package com.iceberg.mp.db;

import java.io.IOException;
import java.io.InputStream;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;

import com.iceberg.mp.Logger;
import com.iceberg.mp.schelduler.Env;
import com.iceberg.mp.schelduler.MTask;
import com.iceberg.mp.server.ServerConfig;
import com.iceberg.mp.vs.client.Result;
import com.iceberg.mp.vs.client.VClientProtocol;
import com.iceberg.mp.vs.vsm.VSMClient;
import com.iceberg.mp.vs.vsm.VSMClientSendResults;
import com.iceberg.mp.ws.wsm.WSMWsmtoldvsTaskPutRequest;
import com.sun.xml.internal.messaging.saaj.util.ByteInputStream;

public class SQLRequests {

	/*
	 * Init db requests;
	 * 
	 */
	private static final String SQL_CREATE_ENVS = 
		"CREATE CACHED TABLE IF NOT EXISTS ENVS(id INT PRIMARY KEY AUTO_INCREMENT," +
		" name VARCHAR(255) NOT NULL)";

	private static final String SQL_CREATE_RULES = 
		"CREATE CACHED TABLE IF NOT EXISTS RULES(id INT PRIMARY KEY AUTO_INCREMENT," +
		" name VARCHAR(255) NOT NULL)";
	
	private static final String SQL_CREATE_USERS = 
		"CREATE CACHED TABLE IF NOT EXISTS USERS(id INT PRIMARY KEY AUTO_INCREMENT, name "+
		"VARCHAR(255) NOT NULL, priv INT NOT NULL)";
	
	private static final String SQL_CREATE_CLIENTS = 
		"CREATE CACHED TABLE IF NOT EXISTS CLIENTS(id INT PRIMARY KEY AUTO_INCREMENT, name "+
		"VARCHAR(255) NOT NULL, status VARCHAR(255) NOT NULL)";
	
	private static final String SQL_DROP_CLIENTS = "DROP TABLE IF EXISTS CLIENTS";
	
	private static final String SQL_CREATE_TASKS = 
		"CREATE CACHED TABLE IF NOT EXISTS TASKS(id INT PRIMARY KEY AUTO_INCREMENT, id_user "+
		"INT NOT NULL, status VARCHAR(255) NOT NULL, size INT, data BLOB)";
	
	private static final String SQL_CREATE_ETASKS = 
		"CREATE CACHED TABLE IF NOT EXISTS ETASKS(id INT PRIMARY KEY AUTO_INCREMENT, id_task "+
		"INT NOT NULL, status VARCHAR(255) NOT NULL, id_env INT NOT NULL)";
	
	private static final String SQL_CREATE_RTASKS = 
		"CREATE CACHED TABLE IF NOT EXISTS RTASKS(id INT PRIMARY KEY AUTO_INCREMENT, id_etask "+
		"INT NOT NULL, status VARCHAR(255) NOT NULL, id_rule INT NOT NULL, id_client INT NOT NULL," +
		" rstatus VARCHAR(255), report BLOB)";
	
	private static final String SQL_CREATE_RESULTS = 
		"CREATE CACHED TABLE IF NOT EXISTS RESULTS(id INT PRIMARY KEY AUTO_INCREMENT, id_rtask "+
		"INT NOT NULL, rstatus VARCHAR(255) NOT NULL, report BLOB)";
	
	public static Statement getTransactionStmt(Connection conn) {
		Statement stmt = null;
		try {
			conn.setAutoCommit(false);
			stmt = conn.createStatement();
		} catch (SQLException e1) {
			Logger.err("SQL can't set set autocommit option in false or create statement.");
		}		
		return stmt;
	}
	
	public static boolean initDb(Connection conn) {
		Statement stmt = getTransactionStmt(conn);
		if(stmt==null) return false;
		try {
			stmt.execute(SQL_CREATE_USERS);
			stmt.execute(SQL_CREATE_RULES);
			stmt.execute(SQL_DROP_CLIENTS);
			stmt.execute(SQL_CREATE_CLIENTS);
			stmt.execute(SQL_CREATE_ENVS);
			stmt.execute(SQL_CREATE_TASKS);
			stmt.execute(SQL_CREATE_ETASKS);
			stmt.execute(SQL_CREATE_RTASKS);
			stmt.execute(SQL_CREATE_RESULTS);
			conn.commit();
		} catch (SQLException e) {
			e.printStackTrace();
			try {
				conn.rollback();
				stmt.close();
			} catch (SQLException e1) {
				e1.printStackTrace();
			}
			return false;
		}
		try {
			stmt.close();
		} catch (SQLException e) {
			e.printStackTrace();
		}
		return true;
	}
	
	@SuppressWarnings("finally")
	public static int registerOrGetUserId(Connection conn, String name) {
		int id = -1;
		Statement stmt = getTransactionStmt(conn);
		if(stmt==null) return id;
		
		try {
			ResultSet rs = stmt.executeQuery("SELECT id FROM USERS WHERE name='"+name+"'");
			if(rs.getRow()==0 && !rs.next()) {
				stmt.execute("INSERT INTO USERS(name,priv) VALUES('"+name+"',0)");
				rs = stmt.executeQuery("SELECT id FROM USERS WHERE NAME='"+name+"'");
				rs.next();
			}
			id = rs.getInt("id");
			rs.close();
			try {
				conn.commit();
				stmt.close();
			} catch (SQLException e) {
				conn.rollback();
				id = -1;
			}
		} catch (SQLException e1) {
			e1.printStackTrace();
		} finally {
			try {
				stmt.close();
			} catch (final SQLException e) {
				e.printStackTrace();
			}
			return id;
		}
	}
	
	@SuppressWarnings("finally")
	public static int registerOrGetEnvId(Connection conn, String name) {
		int id = -1;
		Statement stmt = getTransactionStmt(conn);
		if(stmt==null) return id;
		
		try {
			ResultSet rs = stmt.executeQuery("SELECT id FROM ENVS WHERE name='"+name+"'");
			if(rs.getRow()==0 && !rs.next()) {
				stmt.execute("INSERT INTO ENVS(name) VALUES('"+name+"')");
				rs = stmt.executeQuery("SELECT id FROM ENVS WHERE NAME='"+name+"'");
				rs.next();
			}
			id = rs.getInt("id");
			rs.close();
			try {
				conn.commit();
				stmt.close();
			} catch (SQLException e) {
				conn.rollback();
				id = -1;
			}
		} catch (SQLException e1) {
			e1.printStackTrace();
		} finally {
			try {
				stmt.close();
			} catch (final SQLException e) {
				e.printStackTrace();
			}
			return id;
		}
	}
	
	@SuppressWarnings("finally")
	public static int registerOrGetRuleId(Connection conn, String name) {
		int id = -1;
		Statement stmt = getTransactionStmt(conn);
		if(stmt==null) return id;
		
		try {
			ResultSet rs = stmt.executeQuery("SELECT id FROM RULES WHERE name='"+name+"'");
			if(rs.getRow()==0 && !rs.next()) {
				stmt.execute("INSERT INTO RULES(name) VALUES('"+name+"')");
				rs = stmt.executeQuery("SELECT id FROM RULES WHERE NAME='"+name+"'");
				rs.next();
			}
			id = rs.getInt("id");
			rs.close();
			try {
				conn.commit();
				stmt.close();
			} catch (SQLException e) {
				conn.rollback();
				id = -1;
			}
		} catch (SQLException e1) {
			e1.printStackTrace();
		} finally {
			try {
				stmt.close();
			} catch (final SQLException e) {
				e.printStackTrace();
			}
			return id;
		}
	}
		
	@SuppressWarnings("finally")
	public static int registerOrGetClientId(Connection conn, String name) {
		int id = -1;
		Statement stmt = getTransactionStmt(conn);
		if(stmt==null) return id;
		
		try {
			ResultSet rs = stmt.executeQuery("SELECT id FROM CLIENTS WHERE name='"+name+"'");
			if(rs.getRow()==0 && !rs.next()) {
				stmt.execute("INSERT INTO CLIENTS(name,status) VALUES('"+name+"','"+VClientProtocol.Status.VS_WAIT_FOR_TASK+"')");
				rs = stmt.executeQuery("SELECT id FROM CLIENTS WHERE NAME='"+name+"'");
				rs.next();
			}
			id = rs.getInt("id");
			rs.close();
			try {
				conn.commit();
				stmt.close();
			} catch (SQLException e) {
				conn.rollback();
				id = -1;
			}
		} catch (SQLException e1) {
			e1.printStackTrace();
		} finally {
			try {
				stmt.close();
			} catch (final SQLException e) {
				e.printStackTrace();
			}
			return id;
		}
	}
	
	
	public static boolean puTask(Connection conn, WSMWsmtoldvsTaskPutRequest msg, InputStream data) {
		// зарегистрируем пользователя
		int id_user = registerOrGetUserId(conn, msg.getUser());
		if(id_user<0) return false;
		// зарегистрируем задачу
		return registerTask(conn, id_user, data, msg)==-1?false:true;		
	}
	
	public static boolean setStatus(String table, Connection conn,int id , String status) {
		Statement stmt = getTransactionStmt(conn);
		boolean result = false;
		if(stmt==null) return false;
		try {
			stmt.executeUpdate("UPDATE "+table+" SET status='"+status+"' WHERE id="+id);
			try {
				conn.commit();
				return true;
			} catch (SQLException e) {
				conn.rollback();
				return false;
			}
		} catch (SQLException e1) {
			e1.printStackTrace();
		} finally {
			try {
				stmt.close();
			} catch (final SQLException e) {
				e.printStackTrace();
			}
		}
		return result;	
	}
	
	private static boolean setStatusW(ServerConfig config, String table, int id, String status) {
		Connection conn = null;
		try {
			conn = config.getStorageManager().getConnection();
			return setStatus(table, conn, id, status);
		} catch (SQLException e) {
			e.printStackTrace();
		} finally {
			try {
				conn.close();
			} catch (SQLException e) {
				e.printStackTrace();
			}
		}
		return false;
	}
	
	public static boolean setTaskStatus(Connection conn,int id , String status) {
		return setStatus("TASKS", conn, id, status);
	}
	
	public static boolean setRTaskStatus(Connection conn,int id , String status) {
		return setStatus("RTASKS", conn, id, status);
	}
	
	public static boolean setETaskStatus(Connection conn,int id , String status) {
		return setStatus("ETASKS", conn, id, status);
	}
	
	public static boolean setTaskStatusW(ServerConfig config, int id , String status) {
		return setStatusW(config, "TASKS", id, status);
	}

	public static boolean setRTaskStatusW(ServerConfig config, int id , String status) {
		return setStatusW(config, "RTASKS",id, status);
	}
	
	public static boolean setETaskStatusW(ServerConfig config,int id , String status) {
		return setStatusW(config, "ETASKS",id, status);
	}

	
	
	public static int registerTask(Connection conn, int id_user, InputStream data, WSMWsmtoldvsTaskPutRequest msg) {
		int id=-1;
		PreparedStatement stmt = null;
		Statement st = null;
		try {
			conn.setAutoCommit(false);
			st = conn.createStatement();
			ResultSet result = st.executeQuery("SELECT MAX(id) FROM TASKS");
			if(result.getRow()==0 && !result.next())
				id = 1;	
			else
				id = result.getInt(1)+1;
			result.close();
			stmt = conn.prepareStatement("INSERT INTO TASKS(id,id_user,status,size,data) VALUES("+id+","+id_user+",'"+MTask.Status.TS_WAIT_FOR_VERIFICATION+"',"+msg.getSourceLen()+",?)");
			stmt.setBinaryStream (1, data, msg.getSourceLen());
			stmt.executeUpdate();
			List<Env> envs = msg.getEnvs();
			for(int i=0; i<envs.size(); i++) {
				ResultSet lirs = st.executeQuery("SELECT id FROM ENVS WHERE name='"+envs.get(i).getName()+"'");
				if(lirs.getRow()==0 && !lirs.next()) {
					st.execute("INSERT INTO ENVS(name) VALUES('"+envs.get(i).getName()+"')");
					lirs = st.executeQuery("SELECT id FROM ENVS WHERE NAME='"+envs.get(i).getName()+"'");
					lirs.next();
				}
				int id_env = lirs.getInt("id");
				lirs.close();
				ResultSet eresult = st.executeQuery("SELECT MAX(id) FROM ETASKS");
				int id_etask;
				if(eresult.getRow()==0 && !eresult.next())
					id_etask = 1;	
				else
					id_etask = eresult.getInt(1)+1;
				eresult.close();
				st.executeUpdate("INSERT INTO ETASKS(id, id_task, id_env, status) VALUES("+id_etask+","+id+","+id_env+",'"+MTask.Status.TS_WAIT_FOR_VERIFICATION+"')");
				List<String> rules = envs.get(i).getRules();
				for(int j=0; j<rules.size(); j++) {
					ResultSet lrrs = st.executeQuery("SELECT id FROM RULES WHERE name='"+rules.get(j)+"'");
					if(lrrs.getRow()==0 && !lrrs.next()) {
						st.execute("INSERT INTO RULES(name) VALUES('"+rules.get(j)+"')");
						lrrs = st.executeQuery("SELECT id FROM RULES WHERE NAME='"+rules.get(j)+"'");
						lrrs.next();
					}
					int id_rule = lrrs.getInt("id");
					lrrs.close();
					st.executeUpdate("INSERT INTO RTASKS(id_etask, id_rule, id_client, status) VALUES("+id_etask+","+id_rule+",0,'"+MTask.Status.TS_WAIT_FOR_VERIFICATION+"')");	
				}
			}
			conn.commit();
			stmt.close();
			st.close();
			return id; 
		} catch (SQLException e1) {
			Logger.err("SQL can't set set autocommit option in false or create statement.");
			try {
				e1.printStackTrace();
				conn.rollback();
				if(stmt!=null)
					stmt.close();
				if(st!=null) 
					st.close();
			} catch (SQLException e) {
				e.printStackTrace();
			}
		}
		return id;
	}

	public static boolean puTaskC(ServerConfig config,
			WSMWsmtoldvsTaskPutRequest wsmMsg, InputStream in) {
		Connection conn = null;
		try {
			conn = config.getStorageManager().getConnection();
			return puTask(conn, wsmMsg, in);
		} catch (SQLException e) {
			e.printStackTrace();
		} finally {
			try {
				conn.close();
			} catch (SQLException e) {
				e.printStackTrace();
			}
		}
		return false;
	}


	public static MTask getTaskForClientW(VSMClient msg, ServerConfig config) {
		Connection conn = null;
		try {
			conn = config.getStorageManager().getConnection();
			return getTaskForClient(conn, msg);
		} catch (SQLException e) {
			e.printStackTrace();
		} finally {
			try {
				conn.close();
			} catch (SQLException e) {
				e.printStackTrace();
			}
		}
		return null;
	}
	
	public static MTask getTaskForClient(Connection conn, VSMClient msg) {
		// сначала зарегистририуем клиента, если такого нет
		int id_client = registerOrGetClientId(conn, msg.getName());
		if(id_client<0) return null;
		// теперь возмем для него задачу
		return selectTask(conn, id_client);
	}

	private static MTask selectTask(Connection conn, int id_client) {
		Statement stmt = getTransactionStmt(conn);
		MTask result = null;
		InputStream is = null;
		if(stmt==null) return null;
		try {
			ResultSet rs = stmt.executeQuery("SELECT id, id_rule, id_etask FROM RTASKS WHERE status='"+MTask.Status.TS_VERIFICATION_IN_PROGRESS+"' AND id_client="+id_client+" ORDER BY id_etask LIMIT 1");
			if(rs.getRow()==0 && !rs.next()) 
				return null;
			int id = rs.getInt("id");
			int id_rule = rs.getInt("id_rule");
			int id_etask = rs.getInt("id_etask");
			rs = stmt.executeQuery("SELECT id_task, id_env FROM ETASKS WHERE id="+id_etask);
			if(rs.getRow()==0 && !rs.next()) 
				return null;
			int id_task = rs.getInt("id_task");
			int id_env = rs.getInt("id_env");
			rs = stmt.executeQuery("SELECT name FROM RULES WHERE id="+id_rule);
			if(rs.getRow()==0 && !rs.next()) 
				return null;
			String rule = rs.getString("name");
			rs = stmt.executeQuery("SELECT name FROM ENVS WHERE id="+id_env);
			if(rs.getRow()==0 && !rs.next()) 
				return null;
			String env = rs.getString("name");
			rs = stmt.executeQuery("SELECT data,size FROM TASKS WHERE id="+id_task);	
			if(rs.getRow()==0 && !rs.next()) 
				return null;
			int size = rs.getInt("size");
			is = rs.getBinaryStream("data");
			byte[] data = new byte[size];
			is.read(data);
			result = new MTask(id,data,env+"@"+rule);
			stmt.executeUpdate("UPDATE RTASKS SET status='"+MTask.Status.TS_VERIFICATION_IN_PROGRESS+"' WHERE id="+id);
			conn.commit();
		} catch (SQLException e1) {
			try {
				conn.rollback();
			} catch (SQLException e) {
				e.printStackTrace();
			}
			e1.printStackTrace();
		} catch (IOException e) {
			try {
				conn.rollback();
			} catch (SQLException e1) {
				e1.printStackTrace();
			}
			e.printStackTrace();
		} finally {
			try {
				stmt.close();
			} catch (SQLException e1) {
				e1.printStackTrace();
			}
			try {
				if(is!=null) is.close();
			} catch (IOException e) {
				e.printStackTrace();
			}
		}
		return result;	
	}

	public static boolean setRTaskStatusW_WAIT_FOR_VERIFIFCATION(	ServerConfig config, MTask mtask) {
		return setRTaskStatusW(config, mtask.getId(), MTask.Status.TS_VERIFICATION_IN_PROGRESS+"");
	}

	public static List<Integer> getClientsIdW_W_WAIT_FOR_TASK(StorageManager smanager) {
		Connection conn = null;
		try {
			conn = smanager.getConnection();
			return getClientsId_W_WAIT_FOR_TASK(conn);
		} catch (SQLException e) {
			e.printStackTrace();
		} finally {
			try {
				conn.close();
			} catch (SQLException e) {
				e.printStackTrace();
			}
		}
		return null;
	}

	public static List<Integer> getClientsId_W_WAIT_FOR_TASK(Connection conn) {
		Statement stmt = getTransactionStmt(conn);
		List<Integer> listWFV = new ArrayList<Integer>();
		if(stmt==null) return null;
		try {
			ResultSet rs = stmt.executeQuery("SELECT id FROM CLIENTS WHERE status='"+VClientProtocol.Status.VS_WAIT_FOR_TASK+"'");
			while(rs.next()) {
				listWFV.add(rs.getInt("id"));
			}
			conn.commit();
		} catch (SQLException e1) {
			try {
				conn.rollback();
			} catch (SQLException e) {
				e.printStackTrace();
			}
			e1.printStackTrace();
		} finally {
			try {
				stmt.close();
			} catch (SQLException e1) {
				e1.printStackTrace();
			}
		}	
		return listWFV;
	}
	
	public static List<Integer> getRTasksIdW_WAIT_FOR_VERIFICATION(StorageManager smanager) {
		Connection conn = null;
		try {
			conn = smanager.getConnection();
			return getRTasksId_WAIT_FOR_VERIFICATION(conn);
		} catch (SQLException e) {
			e.printStackTrace();
		} finally {
			try {
				conn.close();
			} catch (SQLException e) {
				e.printStackTrace();
			}
		}
		return null;
	}
	
	public static List<Integer> getRTasksId_WAIT_FOR_VERIFICATION(Connection conn) {
		Statement stmt = getTransactionStmt(conn);
		List<Integer> listWFV = new ArrayList<Integer>();
		if(stmt==null) return null;
		try {
			ResultSet rs = stmt.executeQuery("SELECT id FROM RTASKS WHERE id_client=0 AND status='"+MTask.Status.TS_WAIT_FOR_VERIFICATION+"'");
			while(rs.next()) {
				listWFV.add(rs.getInt("id"));
			}
			conn.commit();
		} catch (SQLException e1) {
			try {
				conn.rollback();
			} catch (SQLException e) {
				e.printStackTrace();
			}
			e1.printStackTrace();
		} finally {
			try {
				stmt.close();
			} catch (SQLException e1) {
				e1.printStackTrace();
			}
		}	
		return listWFV;
	}

	public static boolean setTaskToCLientW(StorageManager smanager, Integer id_client, Integer id_rtask) {
		Connection conn = null;
		try {
			conn = smanager.getConnection();
			return setTaskToCLient(conn, id_client, id_rtask);
		} catch (SQLException e) {
			e.printStackTrace();
		} finally {
			try {
				conn.close();
			} catch (SQLException e) {
				e.printStackTrace();
			}
		}
		return false;
	}

	private static boolean setTaskToCLient(Connection conn, Integer id_client, Integer id_rtask) {
		Statement stmt = getTransactionStmt(conn);
		boolean result = false;
		if(stmt==null) return result;
		try {
			stmt.executeUpdate("UPDATE RTASKS SET status='"+MTask.Status.TS_VERIFICATION_IN_PROGRESS+"', id_client="+id_client+" WHERE id="+id_rtask);
			conn.commit();
			result = true;
		} catch (SQLException e1) {
			try {
				conn.rollback();
			} catch (SQLException e) {
				e.printStackTrace();
			}
			e1.printStackTrace();
		} finally {
			try {
				stmt.close();
			} catch (SQLException e1) {
				e1.printStackTrace();
			}
		}	
		return result;
	}

	public static boolean uploadResultsW(ServerConfig config, VSMClientSendResults resultsMsg) {
		Connection conn = null;
		try {
			conn = config.getStorageManager().getConnection();
			conn.setAutoCommit(false);
			return uploadResults(conn, resultsMsg);
		} catch (SQLException e) {
			e.printStackTrace();
		} finally {
			try {
				conn.close();
			} catch (SQLException e) {
				e.printStackTrace();
			}
		}
		return false;	
	}
	
	public static boolean uploadResults(Connection conn, VSMClientSendResults resultsMsg) {
		PreparedStatement stmt = null;
		Statement st = null;
		try {
			Result[] results = resultsMsg.getResults();
			ByteInputStream bis = null;
			for(int i=0; i<results.length; i++) {
				if(results[i].getRresult().equals("UNSAFE")) {
					stmt = conn.prepareStatement("INSERT INTO RESULTS(id_rtask, rstatus, report) VALUES("
							+resultsMsg.getId()+",'"+results[i].getRresult()+"',?)");
					bis = new ByteInputStream(results[i].getReport(),results[i].getReport().length);
					stmt.setBinaryStream (1, bis , results[i].getReport().length);
				} else {
					stmt = conn.prepareStatement("INSERT INTO RESULTS(id_rtask, rstatus) VALUES("
							+resultsMsg.getId()+",'"+results[i].getRresult()+"')");
				}
				stmt.executeUpdate();
			}
					
			// теперь запишем верхний результат
			st = conn.createStatement();
			st.executeUpdate("UPDATE RTASKS SET status='"+MTask.Status.TS_VERIFICATION_FINISHED+"' WHERE id="+resultsMsg.getId());
			// порверим остальные RTASK'и
			// для этго найдем id_etask
			//
			ResultSet result = st.executeQuery("SELECT id_etask FROM RTASKS WHERE id="+resultsMsg.getId()+" LIMIT 1");
			if(result.getRow()==0 && !result.next()) 
				return false;
			int id_etask = result.getInt("id_etask");
			result.close();
			
			result = st.executeQuery("SELECT id FROM RTASKS WHERE id_etask="+id_etask+"AND status!='"+MTask.Status.TS_VERIFICATION_FINISHED+"'");
			if(result.getRow()==0 && !result.next()) {
				result.close();
				// если RTASK'ов с незавершенным результатом нет, то обновляем etask
				st.executeUpdate("UPDATE ETASKS SET status='"+MTask.Status.TS_VERIFICATION_FINISHED+"' WHERE id="+id_etask);
				// теперь проверяем, есть ли незавершенные e_task'и
				result = st.executeQuery("SELECT id_task FROM ETASKS WHERE id="+id_etask+" LIMIT 1");
				if(result.getRow()==0 && !result.next()) 
					return false;
				int id_task = result.getInt("id_task");
				result.close();
				result = st.executeQuery("SELECT id FROM ETASKS WHERE id_task="+id_task+" AND status!='"+MTask.Status.TS_VERIFICATION_FINISHED+"'");
				if(result.getRow()==0 && !result.next()) {
					result.close();
					// если нет, то обновляем задачу
					st.executeUpdate("UPDATE TASKS SET status='"+MTask.Status.TS_VERIFICATION_FINISHED+"' WHERE id="+id_task);
				} else {
					result.close();
				}
			} else {
				result.close();
			}
			
			conn.commit();
			stmt.close();
			bis.close();
			st.close();
			return true; 
		} catch (SQLException e1) {
			Logger.err("SQL can't set set autocommit option in false or create statement.");
			try {
				e1.printStackTrace();
				conn.rollback();
				if(stmt!=null)
					stmt.close();
				if(st!=null) 
					st.close();
			} catch (SQLException e) {
				e.printStackTrace();
			}
		} catch (IOException e) {
			Logger.err("SQL can't set set autocommit option in false or create statement.");
			try {
				e.printStackTrace();
				conn.rollback();
				if(stmt!=null)
					stmt.close();
				if(st!=null) 
					st.close();
			} catch (SQLException e1) {
				e1.printStackTrace();
			}
			e.printStackTrace();
		}
		return false;
	}
}
