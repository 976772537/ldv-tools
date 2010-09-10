package org.linuxtesting.ldv.online.db;

import java.io.BufferedReader;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.IOException;
import java.io.InputStream;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.linuxtesting.ldv.online.Logger;
import org.linuxtesting.ldv.online.schelduler.Env;
import org.linuxtesting.ldv.online.schelduler.MTask;
import org.linuxtesting.ldv.online.server.ServerConfig;
import org.linuxtesting.ldv.online.vs.client.VClientProtocol;
import org.linuxtesting.ldv.online.vs.vsm.VSMClient;
import org.linuxtesting.ldv.online.vs.vsm.VSMClientSendResults;
import org.linuxtesting.ldv.online.ws.wsm.WSMLdvstowsTaskPutResponse;
import org.linuxtesting.ldv.online.ws.wsm.WSMWsmtoldvsTaskPutRequest;

public class SQLRequests {

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
	
	private static String[] readSQLScript(String script) {
		StringBuffer sbuffer = new StringBuffer();
		BufferedReader fin = null;
		try {
			fin = new BufferedReader(new FileReader(script));
			String tmp = null;
			while((tmp=fin.readLine())!=null)
			{
				if(!(tmp.length()>1 && tmp.charAt(0) == '-' && tmp.charAt(1) == '-')) {
					sbuffer.append(tmp);
				}
			}
			fin.close();
		} catch (FileNotFoundException e)
		{
			Logger.warn("File not found: \""+script+"\".");
		} catch (IOException e) {
			Logger.warn("IO error found while read file: \""+script+"\".");
		} 
		return sbuffer.toString().split(";");
	}
	
	private static Pattern pattern = Pattern.compile(".*create.*if.*not.*exists.*",Pattern.CASE_INSENSITIVE);
	public static boolean isItCreateRequest(String request) {
		Matcher matcher = pattern.matcher(request);
		if (matcher.matches())
			return true;
		return false;
	}
	
	public static boolean initDBTables(Connection conn, String opt, String script) {
		Statement stmt = getTransactionStmt(conn);
		if(stmt==null) return false;
		try {
			String[] commands = readSQLScript(script);
			for(int i=0; i<commands.length; i++) {
				if(opt!=null && opt.length()>0 && opt.equals("true") || isItCreateRequest(commands[i])) {
					Logger.debug("execute:\"" + commands[i] + "\"");
					stmt.addBatch(commands[i]);
				} 
			}
			stmt.executeBatch();
			conn.commit();
		} catch (SQLException e) {
			e.printStackTrace();
			try {
				conn.rollback();
			} catch (SQLException e1) {
				e1.printStackTrace();
			}
			return false;
		} finally {
			closeStatement(stmt);
			closeConnection(conn);
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
			closeResultSet(rs);
			try {
				conn.commit();
			} catch (SQLException e) {
				conn.rollback();
				id = -1;
			}
		} catch (SQLException e1) {
			e1.printStackTrace();
		} finally {
			closeStatement(stmt);
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
			closeStatement(stmt);
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
			closeConnection(conn);
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
			result = true;
		} catch (SQLException e) {
			e.printStackTrace();
		} finally {
			closeStatement(st);
			closeConnection(sconn);
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
		closeResultSet(rs);
		return lastKey;
	}
	
	public static int modifyAndGetIdPrep(Connection conn, InputStream bs, int length, String modify) throws SQLException {
		PreparedStatement stmt = conn.prepareStatement(modify,Statement.RETURN_GENERATED_KEYS);
		stmt.setBinaryStream (1, bs, length);
		stmt.executeUpdate();
		int lastKey = getLastKeyFromStatement(stmt);
		closeStatement(stmt);
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
		closeResultSet(srs);
		return id;
	}
	
	public static int modifyAndGetIdUnsafe2(Statement st, String insertString, String selectString) throws SQLException {
		ResultSet rs = st.executeQuery(selectString);
		if(rs.getRow()==0 && !rs.next()) {
			closeResultSet(rs);
			st.executeUpdate(insertString);
			rs = st.executeQuery(selectString);				
			rs.next();
		}
		int id = rs.getInt("id");
		closeResultSet(rs);
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
					closeResultSet(srs);
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
			closeStatement(stmt);
			closeStatement(st);
			closeStatement(ste);
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
			closeConnection(conn);
			closeConnection(sconn);
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
			closeConnection(conn);
			closeConnection(sconn);
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
				return new MTask("NO TASKS");
			int id = rs.getInt("id");
			int parent_id = rs.getInt("parent_id");
			String env = rs.getString("env");
			String rule = rs.getString("rule");
			closeResultSet(rs);
			rs = stmt.executeQuery("SELECT data,size FROM TASKS WHERE id="+parent_id);	
			if(rs.getRow()==0 && !rs.next()) 
				return null;
			int size = rs.getInt("size");
			is = rs.getBinaryStream("data");	
			byte[] data = new byte[size];
			is.read(data);
			closeResultSet(rs);
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
			closeResultSet(rs);
			st.executeUpdate("UPDATE launches SET status='running' WHERE id="+id);			
			st.close();
			closeStatement(stmt);
			result = new MTask(id, parent_id, env,driver_name, rule, data, "OK");
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
			closeStatement(stmt);
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
			closeConnection(conn);
		}
		return null;
	}
	
	public static List<Integer> getClientsId_W_WAIT_FOR_TASK(Connection conn) {
		Statement stmt = getTransactionStmt(conn);
		List<Integer> listWFV = new ArrayList<Integer>();
		if(stmt==null) return null;
		ResultSet rs = null;
		try {
			rs = stmt.executeQuery("SELECT id FROM CLIENTS WHERE status='"+VClientProtocol.Status.VS_WAIT_FOR_TASK+"'");
			while(rs.next())
				listWFV.add(rs.getInt("id"));
			conn.commit();
		} catch (SQLException e1) {
			try {
				conn.rollback();
			} catch (SQLException e) {
				e.printStackTrace();
			}
			e1.printStackTrace();
		} finally {
			closeResultSet(rs);
			closeStatement(stmt);
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
			closeConnection(conn);
		}
		return null;
	}
	
	public static List<Integer> getSplittedTasksId_WAIT_FOR_VERIFICATION(Connection conn) {
		Statement stmt = getTransactionStmt(conn);
		List<Integer> listWFV = new ArrayList<Integer>();
		if(stmt==null) return null;
		ResultSet rs = null;
		try {
			rs = stmt.executeQuery("SELECT id FROM SPLITTED_TASKS WHERE client_id=0 AND status='"+MTask.Status.TS_WAIT_FOR_VERIFICATION+"'");
			while(rs.next())
				listWFV.add(rs.getInt("id"));
			conn.commit();
		} catch (SQLException e) {
			try {
				conn.rollback();
			} catch (SQLException e1) {
				e1.printStackTrace();
			}
			e.printStackTrace();
		} finally {
			closeResultSet(rs);
			closeStatement(stmt);
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
			closeConnection(conn);
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
			closeStatement(stmt);
			closeStatement(stmt);
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
			closeConnection(conn);
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
			closeResultSet(rs);
			// и запорсим все раздельные задачи
			rs = st.executeQuery("SELECT id FROM SPLITTED_TASKS WHERE parent_id="+parent_id+"AND status!='"+MTask.Status.TS_VERIFICATION_FINISHED+"'");
			if(rs.getRow()==0 && !rs.next()) {
				closeResultSet(rs);
				// если таких нет, то установим статус родительской задачи в FINISHED
				st.executeUpdate("UPDATE TASKS SET status='"+MTask.Status.TS_VERIFICATION_FINISHED+"' WHERE id="+parent_id);
			}
			conn.commit();			
			return true;
		} catch (SQLException e) {
			e.printStackTrace();
		} catch (Throwable e) {
			e.printStackTrace();
		} finally {
			closeStatement(st);
			closeConnection(conn);
		}
		return false;
	}
	

	public static void noSleep(StorageManager manager) {
		Connection conn;
		try {
			conn = manager.getStatsConnection();
			Statement st = conn.createStatement();
			st.executeQuery("SELECT 1;");
			closeStatement(st);
			closeConnection(conn);
		} catch (SQLException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}

	/**
	 * Close the given JDBC Connection and ignore any thrown exception.
	 * This is useful for typical finally blocks in manual JDBC code.
	 * @param con the JDBC Connection to close (may be <code>null</code>)
	 */
	public static void closeConnection(Connection con) {
	    if (con != null) {
	        try {
	        	Logger.debug("Close connection.");
	            con.close();
	        }
	        catch (SQLException ex) {
	            Logger.debug("Could not close JDBC Connection");
	        }
	        catch (Throwable ex) {
	            // We don't trust the JDBC driver: It might throw RuntimeException or Error.
	            Logger.debug("Unexpected exception on closing JDBC Connection");
	        }
	    }
	}
	
	/**
	 * Close the given JDBC Statement and ignore any thrown exception.
	 * This is useful for typical finally blocks in manual JDBC code.
	 * @param stmt the JDBC Statement to close (may be <code>null</code>)
	 */
	public static void closeStatement(Statement stmt) {
	    if (stmt != null) {
	        try {
	            stmt.close();
	        }
	        catch (SQLException ex) {
	            Logger.debug("Could not close JDBC Statement");
	        }
	        catch (Throwable ex) {
	            // We don't trust the JDBC driver: It might throw RuntimeException or Error.
	            Logger.debug("Unexpected exception on closing JDBC Statement");
	        }
	    }
	}

	/**
	 * Close the given JDBC ResultSet and ignore any thrown exception.
	 * This is useful for typical finally blocks in manual JDBC code.
	 * @param rs the JDBC ResultSet to close (may be <code>null</code>)
	 */
	public static void closeResultSet(ResultSet rs) {
	    if (rs != null) {
	        try {
	            rs.close();
	        }
	        catch (SQLException ex) {
	            Logger.debug("Could not close JDBC ResultSet");
	        }
	        catch (Throwable ex) {
	            // We don't trust the JDBC driver: It might throw RuntimeException or Error.
	            Logger.debug("Unexpected exception on closing JDBC ResultSet");
	        }
	    }
	}

	
	
}
