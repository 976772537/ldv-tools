package com.iceberg.mp.db;

import java.io.BufferedInputStream;
import java.io.ByteArrayInputStream;
import java.io.DataInputStream;
import java.io.DataOutputStream;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.List;

import com.iceberg.mp.Logger;
import com.iceberg.mp.schelduler.Env;
import com.iceberg.mp.schelduler.Task;
import com.iceberg.mp.schelduler.VerClient;
import com.iceberg.mp.server.ServerConfig;
import com.iceberg.mp.vs.client.VClient;
import com.iceberg.mp.ws.wsm.WSMWsmtoldvsTaskPutRequest;
import com.sun.xml.internal.ws.message.ByteArrayAttachment;

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
		"INT NOT NULL, status VARCHAR(255) NOT NULL, data BLOB)";
	
	private static final String SQL_CREATE_ETASKS = 
		"CREATE CACHED TABLE IF NOT EXISTS ETASKS(id INT PRIMARY KEY AUTO_INCREMENT, id_task "+
		"INT NOT NULL, status VARCHAR(255) NOT NULL, id_env INT NOT NULL)";
	
	private static final String SQL_CREATE_RTASKS = 
		"CREATE CACHED TABLE IF NOT EXISTS RTASKS(id INT PRIMARY KEY AUTO_INCREMENT, id_etask "+
		"INT NOT NULL, status VARCHAR(255) NOT NULL, id_rule INT NOT NULL, id_client INT NOT NULL)";
	
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
				stmt.execute("INSERT INTO CLIENTS(name,status) VALUES('"+name+"','"+VerClient.Status.VS_WAIT_FOR_TASK+"')");
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
	
	public static boolean setTaskStatus(Connection conn,int id , String status) {
		Statement stmt = getTransactionStmt(conn);
		boolean result = false;
		if(stmt==null) return false;
		try {
			stmt.executeUpdate("UPDATE TASKS SET status='"+status+"' WHERE id="+id);
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
			stmt = conn.prepareStatement("INSERT INTO TASKS(id,id_user,status,data) VALUES("+id+","+id_user+",'"+Task.Status.TS_WAIT_FOR_VERIFICATION+"',?)");
			stmt.setBinaryStream (1, data, msg.getSourceLen());
			stmt.executeUpdate();
			// add etasks
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
				//id, id_parent, id_env, status
				st.executeUpdate("INSERT INTO ETASKS(id, id_task, id_env, status) VALUES("+id_etask+","+id+","+id_env+",'"+Task.Status.TS_WAIT_FOR_VERIFICATION+"')");
				// add rtasks
				List<String> rules = envs.get(i).getRules();
				for(int j=0; j<rules.size(); j++) {
					// TODO: add test for "-1"
					ResultSet lrrs = st.executeQuery("SELECT id FROM RULES WHERE name='"+rules.get(j)+"'");
					if(lrrs.getRow()==0 && !lrrs.next()) {
						st.execute("INSERT INTO RULES(name) VALUES('"+rules.get(j)+"')");
						lrrs = st.executeQuery("SELECT id FROM RULES WHERE NAME='"+rules.get(j)+"'");
						lrrs.next();
					}
					int id_rule = lrrs.getInt("id");
					lrrs.close();
					//id, id_parent, id_rule, id_client, status
					st.executeUpdate("INSERT INTO RTASKS(id_etask, id_rule, id_client, status) VALUES("+id_etask+","+id_rule+",0,'"+Task.Status.TS_WAIT_FOR_VERIFICATION+"')");
					// add rtasks					
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
			// TODO Auto-generated catch block
			e.printStackTrace();
		} finally {
			try {
				conn.close();
			} catch (SQLException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
		}
		return false;
	}
}
