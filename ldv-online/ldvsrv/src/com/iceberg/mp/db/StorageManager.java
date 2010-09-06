package com.iceberg.mp.db;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.Map;

import com.iceberg.mp.Logger;

import java.io.File;
import java.io.IOException;

import org.apache.commons.dbcp.ConnectionFactory;
import org.apache.commons.dbcp.DriverManagerConnectionFactory;
import org.apache.commons.dbcp.PoolableConnectionFactory;
import org.apache.commons.dbcp.PoolingDataSource;
import org.apache.commons.pool.impl.GenericObjectPool;

public class StorageManager {
	
	private boolean InnerDBConnectionPool = false;
	private boolean StatsDBConnectionPool = false;
	
	private String statsDBScript;
	private String innerDBScript;
	
	private String workdir;
	private String dbworkdir;
	private String bins;
	
	private String dbuser="ldvsuser";
	private String dbpass="ldvs1604";
	private String dbhost="localhost";
	
	private String statsDbuser;
	private String statsDbpass;
	private String statsDbhost;
	private String statsDbname;
	private String statsDbport;

	private PoolingDataSource statsPoolingDataSource;
	private PoolingDataSource poolingDataSource;

	
	private static final String connectionPrefix = "jdbc";
	private static final String dbType = "h2:tcp://";
	private static final String dbdriver = "org.h2.Driver";
	private String dboptions = ";LOCK_MODE=3;AUTO_SERVER=TRUE;AUTO_RECONNECT=TRUE";
	
	private String connectionString;
	
	private static final String statsConnectionPrefix = "jdbc";
	private static final String statsDbType = "mysql";
	private static final String statsDbdriver = "com.mysql.jdbc.Driver";
	private String statsDboptions = "?autoReconnect=true";
	
	private String statsConnectionString;
	private String statsIsClean;
	private String h2IsClean;
	
	public StorageManager(Map<String, String> params) {
		this.workdir = params.get("WorkDir");
		this.dbworkdir = workdir+"/db";
		this.bins = workdir+"/bins";
		// TODO: add test for params
		this.statsDbhost = params.get("StatsDBHost");
		this.statsDbname = params.get("StatsDBName");
		this.statsDbuser = params.get("StatsDBUser");
		this.statsDbpass = params.get("StatsDBPass");
		this.statsDbport = params.get("StatsDBPort");

		this.statsIsClean = params.get("CleanStatsOnRestart");
		this.h2IsClean = params.get("CleanH2OnRestart");
		
		this.statsDBScript = params.get("StatsDBScript");
		this.innerDBScript = params.get("InnerDBScript");
		
		if(params.get("InnerDBConnectionPool").equals("on")) {
			this.InnerDBConnectionPool = true;	
		}
		
		if(params.get("StatsDBConnectionPool").equals("on")) {
			this.StatsDBConnectionPool = true;	
		}

		this.statsDboptions = params.get("StatsDBConnectOptions");
		this.dboptions = params.get("InnerDBConnectOptions");
	}
	
	public void initInnerDB() throws IOException, SQLException, ClassNotFoundException {
		connectionString = connectionPrefix+":"+dbType+dbhost+dbworkdir+dboptions;
		initDB(dbdriver, connectionString, dbuser, dbpass, innerDBScript, statsIsClean);
		if(InnerDBConnectionPool) {
			poolingDataSource = createDBConnectionsPool(connectionString, dbuser, dbpass);
		}
	}
	
	public void initStatsDB() throws IOException, SQLException, ClassNotFoundException {
		statsConnectionString = statsConnectionPrefix+":"+statsDbType+"://"+statsDbhost+":"+statsDbport+"/"+statsDbname+statsDboptions;
		initDB(statsDbdriver, statsConnectionString, statsDbuser, statsDbpass, statsDBScript, statsIsClean);
		if(StatsDBConnectionPool) {
			statsPoolingDataSource = createDBConnectionsPool(statsConnectionString, statsDbuser, statsDbpass);
		}	
	}

	public void initDB(String DBdriver, String connectionStr, String DBuser, String DBpass, String DBscript, String ISclean) throws IOException, SQLException, ClassNotFoundException {
		Logger.debug("Open JDBC driver: \"" + dbdriver + "\"...");
		Class.forName(DBdriver);
		Logger.debug("Ok");
		Logger.trace("Connection URL:\""+connectionStr+"\"");
		//statsPoolingDataSource = createDBConnectionsPool(connectionStr, DBuser, DBpass);
		Connection conn = DriverManager.getConnection(connectionStr, DBuser, DBpass);
		//Connection conn = statsPoolingDataSource.getConnection();
		Logger.trace("Initialize tables from DB script: \""+DBscript+"\"...");
		SQLRequests.initDBTables(conn,ISclean,DBscript);
		Logger.trace("Database successfully initialized.");
	}
	
	public static PoolingDataSource createDBConnectionsPool(String connectionString, String username, String password) {
		GenericObjectPool connectionPool = new GenericObjectPool(null);
		ConnectionFactory connectionFactory = new DriverManagerConnectionFactory(connectionString, username, password);
		new PoolableConnectionFactory(connectionFactory, connectionPool, null,null, false, true);
		return new PoolingDataSource(connectionPool);		
	}
	
	public void init() throws IOException, SQLException, ClassNotFoundException {
		File fileWorkdir = new File(bins);
		if(!fileWorkdir.exists()) {
			Logger.debug("Create storage dirs...");
			if(!fileWorkdir.mkdirs()) {
				Logger.err("Can't create work dirs.");
				throw new IOException();
			}
			Logger.info("Ok.");
		}
		
		Logger.debug("Initialize inner DB...");
		initInnerDB();
		Logger.debug("Initialize stats DB...");
		initStatsDB();
	}

	private static int h2ConnNumber=0;
	public synchronized Connection getConnection() throws SQLException {
		Logger.debug("Get h2 connection number: "+ ++h2ConnNumber);
		if(InnerDBConnectionPool) 
			return poolingDataSource.getConnection();
		else
			return DriverManager.getConnection(connectionString, dbuser, dbpass);
	}
	
	private static int stConnNumber=0;
	public synchronized Connection getStatsConnection() throws SQLException {
		Logger.debug("Get stats connection number: "+ ++stConnNumber);
		if(StatsDBConnectionPool)
			return statsPoolingDataSource.getConnection();
		else
			return DriverManager.getConnection(statsConnectionString, statsDbuser, statsDbpass);
		// пул почему-то виснет на 7-8 запросе
		// TODO: скачать исходники и разобраться!
		/*
		 * 1. Start VServer in debug mode
		 * 2. Start VClient in debug mode
		 * 3. Upload files in next steps
		 *  - hd[vr-core
		 *  - hdpvr-video
		 *  - radio-gemtek-pci
		 *  - serial-safe
		 *  - serial-unsafe
		 *  - wl12xx
		 *  - ali-ircc
		 *  - usb-core-devices
		 *  - usb-core-message
		 * 4. On last driver we have deadlock in the
		 *    connection pool request for connection 
		 *    
		 *    Any connections not closed by me?
		 *    And pool wait while i am close connections?
		 */
	}
	
	@Override
	protected void finalize() throws Throwable {
		super.finalize();
	}
	
}
