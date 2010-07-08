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
import com.iceberg.mp.vs.client.VClientProtocol;
import com.iceberg.mp.vs.vsm.VSMClient;
import com.iceberg.mp.vs.vsm.VSMClientSendResults;
import com.iceberg.mp.ws.wsm.WSMLdvstowsTaskPutResponse;
import com.iceberg.mp.ws.wsm.WSMWsmtoldvsTaskPutRequest;

public class SQLRequests {

	/*
	 * Init db H2 - inner pulls and drivers sources ;
	 * 
	 * 
	 */
	private static final String SQL_DROP_TASKS = "DROP TABLE IF EXISTS TASKS";
	private static final String SQL_DROP_SPLITTED_TASKS = "DROP TABLE IF EXISTS SPLITTED_TASKS";
	private static final String SQL_DROP_CLIENTS = "DROP TABLE IF EXISTS CLIENTS";

	
	private static final String SQL_CREATE_CLIENTS = 
		"CREATE CACHED TABLE IF NOT EXISTS CLIENTS(id INT PRIMARY KEY AUTO_INCREMENT, name "+
		"VARCHAR(255) NOT NULL, status VARCHAR(255) NOT NULL)";
	
	private static final String SQL_CREATE_TASKS = 
		"CREATE CACHED TABLE IF NOT EXISTS TASKS(id INT PRIMARY KEY AUTO_INCREMENT, " +
		"status VARCHAR(255) NOT NULL, size INT, data BLOB)";
		
	private static final String SQL_CREATE_SPLITTED_TASKS = 
		"CREATE CACHED TABLE IF NOT EXISTS SPLITTED_TASKS(id INT PRIMARY KEY AUTO_INCREMENT, parent_id "+
		"INT NOT NULL, env VARCHAR(100), rule CHAR(5), status VARCHAR(255) NOT NULL, client_id INT NOT NULL)";
	
	/*
	 * Init db stats
	 * 
	 * 
	 * 
	 */
	
	
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
	
	public static boolean initInnerDbTables(Connection conn) {
		Statement stmt = getTransactionStmt(conn);
		if(stmt==null) return false;
		try {
			stmt.execute(SQL_DROP_CLIENTS);
			stmt.execute(SQL_DROP_TASKS);
			stmt.execute(SQL_DROP_SPLITTED_TASKS);
			
			stmt.execute(SQL_CREATE_CLIENTS);
			stmt.execute(SQL_CREATE_TASKS);
			stmt.execute(SQL_CREATE_SPLITTED_TASKS);
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

	/**
	 * @param conn - connection to inner db
	 * @param name - unique name of client (might be hotname or ip or other...)
	 * @return client unique identificator
	 */
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
	
	
	public static boolean puTask(Connection conn, Connection sconn,  WSMWsmtoldvsTaskPutRequest msg, WSMLdvstowsTaskPutResponse ldvtowsResponse, InputStream data) {
		// зарегистрируем задачу во внутренней ДБ
		int id = registerTask(conn, sconn, data, msg);
		// TODO: регистрируем задачу во нешней ДБ
		// устанавливаем id-шник задачи для ответа
		ldvtowsResponse.setId(id);
		return id==-1?false:true;		
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
	
	public static boolean setSplittedTaskStatusW(ServerConfig config, int id , String status) {
		// set status queued to external db
		return setStatsStatusForTask(config,"queued",id) && setStatusW(config, "SPLITTED_TASKS",id, status);
	}
	
	public static boolean setStatsStatusForTask(ServerConfig config, String status, int id) {
		boolean result = false;
		Connection sconn = null;
		Statement st = null;
		try {
			sconn = config.getStorageManager().getStatsConnection();
			st = sconn.createStatement();
			st.executeUpdate("UPDATE launches SET status='queued' WHERE id="+id);
			st.close();
			result = true;
		} catch (SQLException e) {
			e.printStackTrace();
		} finally {
			try {
				sconn.close();
			} catch (SQLException e1) {
				e1.printStackTrace();
			}
		}	
		return result;		
	}
	
	/**
	 * не делает false на autoCommit
	 * @param conn
	 * @param bs
	 * @param modify
	 * @return
	 * @throws SQLException 
	 * @throws SQLException 
	 */
	public static int getLastKeyFromStatement(Statement st) throws SQLException {
		ResultSet rs = st.getGeneratedKeys();
		int lastKey = -1;
		if (rs.next()) lastKey = rs.getInt(1);
		rs.close();
		return lastKey;
	}
	
	public static int modifyAndGetIdPrep(Connection conn, InputStream bs, int length, String modify) throws SQLException {
		PreparedStatement stmt = conn.prepareStatement(modify,Statement.RETURN_GENERATED_KEYS);
		stmt.setBinaryStream (1, bs, length);
		stmt.executeUpdate();
		int lastKey = getLastKeyFromStatement(stmt);
		stmt.close();
		return lastKey;
	}
	
	public static int modifyAndGetId(Statement st, String modify) throws SQLException {
		st.executeUpdate(modify, Statement.RETURN_GENERATED_KEYS);
		return getLastKeyFromStatement(st);
	}
	
	public static int modifyAndGetIdUnsafe(Statement st, String insertString, String selectString) throws SQLException {
		st.executeUpdate(insertString);
		ResultSet srs = st.executeQuery(selectString);
		srs.next();
		int id = srs.getInt(1); 
		srs.close();		
		return id;
	}
	
	public static int modifyAndGetIdUnsafe2(Statement st, String insertString, String selectString) throws SQLException {
		ResultSet rs = st.executeQuery(selectString);
		if(rs.getRow()==0 && !rs.next()) {
			rs.close();
			st.executeUpdate(insertString);
			rs = st.executeQuery(selectString);				
			rs.next();
		}
		int id = rs.getInt("id");
		rs.close();
		return id;
	}
	
	public static int registerTask(Connection conn, Connection sconn, InputStream data, WSMWsmtoldvsTaskPutRequest msg) {
		int id=-1;
		PreparedStatement stmt = null;
		Statement ste = null;
		Statement st = null;
		try {
			conn.setAutoCommit(false);
			id =modifyAndGetIdPrep(conn, data, msg.getSourceLen(), "INSERT INTO TASKS(status,size,data) VALUES('"+MTask.Status.TS_WAIT_FOR_VERIFICATION+"',"+msg.getSourceLen()+",?)");	
			st = conn.createStatement();
			// STATS DB LOGIC
			sconn.setAutoCommit(false);
			// and now register task in stats db
			ste = sconn.createStatement();
			// заливаем в tasks  без транзакций - задачу заливает только один поток - планировщик(
			// сторона веб-морды)
			ste.executeUpdate("INSERT INTO tasks(id,username,timestamp) VALUES("+id+",'"+msg.getUser()+"',now());");
			// заливаем в drivers

			//int driver_id = modifyAndGetIdUnsafe(ste, "INSERT IGNORE INTO drivers(name, origin) VALUES('"+msg.getDriver()+"','external')", "SELECT id FROM drivers WHERE name='"+msg.getDriver()+"' AND origin ='external';");
			int driver_id = modifyAndGetIdUnsafe2(ste, "INSERT IGNORE INTO drivers(name, origin) VALUES('"+msg.getDriver()+'_'+id+"','external')", "SELECT id FROM drivers WHERE name='"+msg.getDriver()+'_'+id+"' AND origin ='external';");
			
			
			int toolset_id = modifyAndGetIdUnsafe(ste, "INSERT IGNORE INTO toolsets(version) VALUES('current')","SELECT id FROM toolsets WHERE version='current' AND verifier='model-specific';");
			ResultSet srs = null;
			List<Env> envs = msg.getEnvs();			
			for(Env env : envs) {
				
				int env_id = modifyAndGetIdUnsafe2(ste,"INSERT INTO environments(version,kind) VALUES('"+env.getName()+"','vanilla')" , "SELECT id FROM environments WHERE version='"+env.getName()+"' AND kind='vanilla';");	
				
				List<String> rules = env.getRules();
				for(String rule : rules) {
					// заливаем модель если ее нет
					int rule_id = modifyAndGetIdUnsafe2(ste, "INSERT INTO rule_models(name) VALUES('"+rule+"')", "SELECT id FROM rule_models WHERE name='"+rule+"';");
					// заливаем launches					
					Logger.trace("INSERT INTO launches(driver_id, toolset_id, environment_id, rule_model_id, task_id, status, trace_id, scenario_id) "+
							"VALUES("+driver_id+","+toolset_id+","+env_id+","+rule_id+","+id+",'queued',null,null)");
					ste.executeUpdate("INSERT INTO launches(driver_id, toolset_id, environment_id, rule_model_id, task_id, status, trace_id, scenario_id) "+
							"VALUES("+driver_id+","+toolset_id+","+env_id+","+rule_id+","+id+",'queued',null,null)");					
					//sconn.commit();
					// заливаем splitted_tasks
					// чтобы синхронизировать номера мы выбираем номер из таблицы launches, так как 
					// только из нее можно взять уникальный id задачи по другим уникальным в сумме полям
					// далее под этим номером заливаем задачу во внутреннюю БД
					Logger.trace("SELECT id FROM launches WHERE driver_id="+driver_id+" AND toolset_id="+toolset_id+
							" AND environment_id="+env_id+" AND rule_model_id="+rule_id+" AND task_id="+id+" AND status='queued' " +
							" AND trace_id IS NULL AND scenario_id IS NULL;");
					
					srs = ste.executeQuery("SELECT id FROM launches WHERE driver_id="+driver_id+" AND toolset_id="+toolset_id+
							" AND environment_id="+env_id+" AND rule_model_id="+rule_id+" AND task_id="+id+" AND status='queued' " +
							" AND trace_id IS NULL AND scenario_id IS NULL;");
					srs.next();
					int launch_id = srs.getInt("id"); 
					srs.close();
					//sconn.commit();
					//conn.commit();
					Logger.trace("INSERT INTO SPLITTED_TASKS(id,parent_id, env, rule, status, client_id) " +
							"VALUES("+ launch_id +","+id+", '"+env.getName()+"','"+rule+"','"+MTask.Status.TS_WAIT_FOR_VERIFICATION+"',0)");					
					st.execute("INSERT INTO SPLITTED_TASKS(id,parent_id, env, rule, status, client_id) " +
									"VALUES("+ launch_id +","+id+", '"+env.getName()+"','"+rule+"','"+MTask.Status.TS_WAIT_FOR_VERIFICATION+"',0)");					
					
				}
			}
			try {
				sconn.commit();
				conn.commit();
			} catch(SQLException e) {
				e.printStackTrace();
				sconn.rollback();
				conn.rollback();
				return -1;
			}
			return id; 
		} catch (SQLException e) {
			e.printStackTrace();
		} catch (Throwable e) {
			e.printStackTrace();
		} finally {
			try {
				if(stmt!=null)
					stmt.close();
				if(st!=null) 
					st.close();
				if(ste!=null)
					ste.close();
			} catch (SQLException e) {
				e.printStackTrace();
			}
		}
		return id;
	}

	public static boolean puTaskC(ServerConfig config,
			WSMWsmtoldvsTaskPutRequest wsmMsg, WSMLdvstowsTaskPutResponse ldvtowsResponse, InputStream in) {
		Connection conn = null;
		Connection sconn = null;
		try {
			conn = config.getStorageManager().getConnection();
			sconn = config.getStorageManager().getStatsConnection();
			return puTask(conn, sconn, wsmMsg, ldvtowsResponse, in);
		} catch (SQLException e) {
			e.printStackTrace();
		} finally {
			try {
				if(conn!=null)
					conn.close();
				if(sconn!=null)
					conn.close();
			} catch (SQLException e) {
				e.printStackTrace();
			}
		}
		return false;
	}


	public static MTask getTaskForClientW(VSMClient msg, ServerConfig config) {
		Connection conn = null;
		Connection sconn = null;
		try {
			conn = config.getStorageManager().getConnection();
			sconn = config.getStorageManager().getStatsConnection();
			return getTaskForClient(conn, sconn, msg);
		} catch (SQLException e) {
			e.printStackTrace();
		} finally {
			try {
				if(conn!=null)
					conn.close();
				if(sconn!=null)
					sconn.close();
			} catch (SQLException e) {
				e.printStackTrace();
			}
		}
		return null;
	}
	
	public static MTask getTaskForClient(Connection conn, Connection sconn, VSMClient msg) {
		// сначала зарегистририуем клиента, если такого нет
		int id_client = registerOrGetClientId(conn, msg.getName());
		if(id_client<0) return null;
		// теперь возмем для него задачу
		return selectSplittedTaskForClient(conn, sconn, id_client);
	}

	private static MTask selectSplittedTaskForClient(Connection conn, Connection sconn, int client_id) {
		Statement stmt = getTransactionStmt(conn);
		MTask result = null;
		InputStream is = null;
		if(stmt==null) return null;
		try {
			ResultSet rs = stmt.executeQuery("SELECT id, env, rule, parent_id FROM SPLITTED_TASKS WHERE status='"
					+MTask.Status.TS_QUEUED+"' AND client_id="+client_id+" ORDER BY parent_id LIMIT 1");
			if(rs.getRow()==0 && !rs.next()) 
				return null;
			int id = rs.getInt("id");
			int parent_id = rs.getInt("parent_id");
			String env = rs.getString("env");
			String rule = rs.getString("rule");
			rs.close();
			
			rs = stmt.executeQuery("SELECT data,size FROM TASKS WHERE id="+parent_id);	
			if(rs.getRow()==0 && !rs.next()) 
				return null;
			int size = rs.getInt("size");
			is = rs.getBinaryStream("data");	
			byte[] data = new byte[size];
			is.read(data);
			rs.close();
			stmt.executeUpdate("UPDATE SPLITTED_TASKS SET status='"+MTask.Status.TS_VERIFICATION_IN_PROGRESS+"' WHERE id="+id);
			try {
				conn.commit();
			} catch(SQLException e) {
				conn.rollback();
				e.printStackTrace();
				return null;
			}
			// STATS DB LOGIC
			// update status from queued to running
			sconn.setAutoCommit(false);
			Statement st = sconn.createStatement();
			rs = st.executeQuery("SELECT name FROM drivers WHERE id=(SELECT driver_id FROM launches WHERE id="+id+")");
			if(rs.getRow()==0 && !rs.next()) 
				return null;
			String driver_name = rs.getString("name");
			rs.close();
			st.executeUpdate("UPDATE launches SET status='running' WHERE id="+id);			
			st.close();
			result = new MTask(id, parent_id, env,driver_name, rule, data);
			try {
				sconn.commit();
			} catch(SQLException e) {
				sconn.rollback();
				result = null;
				e.printStackTrace();
				return null;
			}			
		} catch (SQLException e1) {
			result = null;
			try {
				conn.rollback();
			} catch (SQLException e) {
				e.printStackTrace();
			}
			e1.printStackTrace();
		} catch (IOException e) {
			result = null;
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

	public static boolean setSplittedTaskStatusW_WAIT_FOR_VERIFIFCATION(ServerConfig config, MTask mtask) {
		return setSplittedTaskStatusW(config, mtask.getId(), MTask.Status.TS_VERIFICATION_IN_PROGRESS+"");
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
			rs.close();
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
	
	public static List<Integer> getSplittedTasksIdW_WAIT_FOR_VERIFICATION(StorageManager smanager) {
		Connection conn = null;
		try {
			conn = smanager.getConnection();
			return getSplittedTasksId_WAIT_FOR_VERIFICATION(conn);
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
	
	public static List<Integer> getSplittedTasksId_WAIT_FOR_VERIFICATION(Connection conn) {
		Statement stmt = getTransactionStmt(conn);
		List<Integer> listWFV = new ArrayList<Integer>();
		if(stmt==null) return null;
		try {
			ResultSet rs = stmt.executeQuery("SELECT id FROM SPLITTED_TASKS WHERE client_id=0 AND status='"+MTask.Status.TS_WAIT_FOR_VERIFICATION+"'");
			while(rs.next())
				listWFV.add(rs.getInt("id"));
			conn.commit();
			rs.close();
		} catch (SQLException e) {
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
		}	
		return listWFV;
	}

	public static boolean setSplittedTaskToCLientW(StorageManager smanager, int client_id, int splitted_task_id) {
		Connection conn = null;
		try {
			conn = smanager.getConnection();
			return setSplittedTaskToCLient(conn, client_id, splitted_task_id);
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

	private static boolean setSplittedTaskToCLient(Connection conn, Integer client_id, Integer splitted_task_id) {
		Statement stmt = getTransactionStmt(conn);
		boolean result = false;
		if(stmt==null) return result;
		try {
			stmt.executeUpdate("UPDATE SPLITTED_TASKS SET status='"
					+MTask.Status.TS_QUEUED+"', client_id="+client_id+" WHERE id="+splitted_task_id);
			stmt.close();
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

	public static boolean setSplittedTaskResultW(ServerConfig config, VSMClientSendResults resultsMsg) {
		Connection conn = null;
		try {
			conn = config.getStorageManager().getConnection();
			conn.setAutoCommit(false);
			return setSplittedTaskResult(conn, resultsMsg);
		} catch (SQLException e) {
			e.printStackTrace();
		} catch (Throwable e) {
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
	
	public static boolean setSplittedTaskResult(Connection conn, VSMClientSendResults resultsMsg) {
		Statement st = null;
		try {								
			st = conn.createStatement();
				st.executeUpdate("UPDATE SPLITTED_TASKS SET status='"
						+resultsMsg.getStatus()+"' WHERE id="+resultsMsg.getId());
			// теперь порверим - все ли раздельные задачи для родительской задачи завершены?
			// для этого найдем parent_id
			ResultSet rs = st.executeQuery("SELECT parent_id FROM SPLITTED_TASKS WHERE id="+resultsMsg.getId()+" LIMIT 1");
			if(rs.getRow()==0 && !rs.next()) 
				return false;
			int parent_id = rs.getInt("parent_id");
			rs.close();
			// и запорсим все раздельные задачи
			rs = st.executeQuery("SELECT id FROM SPLITTED_TASKS WHERE parent_id="+parent_id+"AND status!='"+MTask.Status.TS_VERIFICATION_FINISHED+"'");
			if(rs.getRow()==0 && !rs.next()) {
				rs.close();
				// если таких нет, то установим статус родительской задачи в FINISHED
				st.executeUpdate("UPDATE TASKS SET status='"+MTask.Status.TS_VERIFICATION_FINISHED+"' WHERE id="+parent_id);
			}
			st.close();
			conn.commit();			
			return true;
		} catch (SQLException e) {
			e.printStackTrace();
		} catch (Throwable e) {
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
	
	public static String statsDropScript1="drop table if exists launches;";
	public static String statsDropScript2="drop table if exists sources;";
	public static String statsDropScript3="drop table if exists problems_stats;";
	public static String statsDropScript4="drop table if exists problems;";
	public static String statsDropScript5="drop table if exists traces;";
	public static String statsDropScript6="drop table if exists stats;";
	public static String statsDropScript7="drop table if exists scenarios;";
	public static String statsDropScript8="drop table if exists rule_models;";
	public static String statsDropScript9="drop table if exists drivers;";
	public static String statsDropScript10="drop table if exists environments;";
	
	public static String statsDropScript11="drop table if exists tasks;";
	public static String statsDropScript12="drop table if exists toolsets;";
	
	
	public static String statsCreateScript1 = "create table if not exists environments (id INT(10) UNSIGNED NOT NULL AUTO_INCREMENT, version VARCHAR(50) NOT NULL, kind VARCHAR(20), PRIMARY KEY (id)) ENGINE=InnoDB;";
	public static String statsCreateScript2 = "create table if not exists drivers (id int(10) unsigned not null auto_increment, name varchar(255) not null, origin enum('kernel','external') not null, primary key (id), key (name)) ENGINE=InnoDB;";
	public static String statsCreateScript3 = "create table if not exists rule_models(id int(10) unsigned not null auto_increment,name varchar(20), description varchar(200), primary key (id)) ENGINE=InnoDB;";
	public static String statsCreateScript4 = "create table if not exists toolsets(id int(10) unsigned not null auto_increment, version varchar(100) not null, verifier varchar(100) not null default \"model-specific\", primary key(id), unique (version,verifier), key (version), key (verifier)) ENGINE=InnoDB;";	
	public static String statsCreateScript5 = "create table if not exists scenarios(id int(10) unsigned not null auto_increment, driver_id int(10) unsigned not null, executable varchar(255) not null, main varchar(100) not null, primary key (id), foreign key (driver_id) references drivers(id)	) ENGINE=InnoDB;";
	public static String statsCreateScript6 = "create table if not exists stats(id int(10) unsigned not null auto_increment, success boolean not null default false,	time int(10) not null default 0, loc int(10) not null default 0, description text, primary key (id)) ENGINE=InnoDB;";
	public static String statsCreateScript7 = "create table if not exists traces(id int(10) unsigned not null auto_increment, build_id int(10) unsigned not null, maingen_id int(10) unsigned, dscv_id int(10) unsigned,	ri_id int(10) unsigned, rcv_id int(10) unsigned,result enum('safe','unsafe','unknown') not null default 'unknown', error_trace mediumtext, verifier varchar(100), primary key (id), foreign key (build_id) references stats(id), foreign key (maingen_id) references stats(id), foreign key (dscv_id) references stats(id),	foreign key (ri_id) references stats(id), foreign key (rcv_id) references stats(id)) ENGINE=InnoDB;"; 
	public static String statsCreateScript8 = "create table if not exists sources(id int(10) unsigned not null auto_increment, trace_id int(10) unsigned not null, name varchar(255) not null, contents blob, primary key (id), foreign key (trace_id) references traces(id)	) ENGINE=InnoDB;";
	public static String statsCreateScript9 = "create table if not exists tasks(id int(10) unsigned not null auto_increment, username varchar(50), timestamp datetime, driver_spec varchar(255), driver_spec_origin enum('kernel','external'), description text,	primary key (id)) ENGINE=InnoDB;";
	public static String statsCreateScript10 = "create table if not exists launches(id int(10) unsigned not null auto_increment, driver_id int(10) unsigned not null, toolset_id int(10) unsigned not null, environment_id int(10) unsigned not null, rule_model_id int(10) unsigned, scenario_id int(10) unsigned, trace_id int(10) unsigned, task_id int(10) unsigned, status enum('queued','running','failed','finished') not null, primary key (id), UNIQUE (driver_id,toolset_id,environment_id,rule_model_id,scenario_id,task_id), foreign key (driver_id) references drivers(id), foreign key (toolset_id) references toolsets(id), foreign key (environment_id) references environments(id), foreign key (rule_model_id) references rule_models(id), foreign key (scenario_id) references scenarios(id), foreign key (trace_id) references traces(id),	foreign key (task_id) references tasks(id)) ENGINE=InnoDB;";
	
	public static String statsCreateScript11 = "create table if not exists problems(id int(10) unsigned not null auto_increment, name varchar(100), description text, PRImary key (id), key (name)) ENGINE=InnoDB;";
	public static String statsCreateScript12 = "create table if not exists problems_stats(stats_id int(10) unsigned not null, problem_id int(10) unsigned not null, unique (stats_id,problem_id), foreign key (stats_id) references stats(id) on delete cascade, foreign key (problem_id) references problems(id) on delete cascade) ENGINE=InnoDB;";

	
	
	public static void initStatsDbTables(Connection conn) {
		Statement stmt = getTransactionStmt(conn);
		try {
			// drop block
			stmt.execute(statsDropScript1);
			stmt.execute(statsDropScript2);
			stmt.execute(statsDropScript3);
			stmt.execute(statsDropScript4);
			stmt.execute(statsDropScript5);
			stmt.execute(statsDropScript6);
			stmt.execute(statsDropScript7);
			stmt.execute(statsDropScript8);
			stmt.execute(statsDropScript9);
			stmt.execute(statsDropScript10);
			
			// add drop block
			stmt.execute(statsDropScript11);
			stmt.execute(statsDropScript12);
			
			// create block IF EXISTS
			stmt.execute(statsCreateScript1);
			stmt.execute(statsCreateScript2);
			stmt.execute(statsCreateScript3);
			stmt.execute(statsCreateScript4);
			stmt.execute(statsCreateScript5);
			stmt.execute(statsCreateScript6);
			stmt.execute(statsCreateScript7);
			stmt.execute(statsCreateScript8);
			stmt.execute(statsCreateScript9);
			stmt.execute(statsCreateScript10);
			stmt.execute(statsCreateScript11);
			stmt.execute(statsCreateScript12);
			
			conn.commit();
		} catch (SQLException e) {
			e.printStackTrace();
			try {
				conn.rollback();
			} catch (SQLException e1) {
				// TODO Auto-generated catch block
				e1.printStackTrace();
			}
		} finally {
			try {
				conn.close();
			} catch (SQLException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
		}
	}

}
