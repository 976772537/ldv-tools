package com.iceberg.mp.db;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.Map;

import com.iceberg.mp.Logger;
import java.io.File;
import java.io.IOException;

public class StorageManager {

	private String workdir;
	private String dbworkdir;
	private String bins;
	
	private String dbuser="ldvsuser";
	private String dbpass="ldvs1604";
	
	private String statsDbuser;
	private String statsDbpass;
	private String statsDbhost;
	private String statsDbname;
	private String statsDbport;

	
	private static final String connectionPrefix = "jdbc";
	private static final String dbType = "h2";
	private static final String dbdriver = "org.h2.Driver";
	private static final String dblockmode = ";LOCK_MODE=3;AUTO_SERVER=TRUE";

	private String connectionString;

	private Connection statsSingleConnection;
	
	private Connection singleConnection;
	
	private static final String statsConnectionPrefix = "jdbc";
	private static final String statsDbType = "mysql";
	private static final String statsDbdriver = "com.mysql.jdbc.Driver";
	
	private String statsConnectionString;
	
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
		
	}
	
	public void initInnerDB() throws IOException, SQLException, ClassNotFoundException {
		//1. создаем директории, если их нет
		File fileWorkdir = new File(bins);
		if(!fileWorkdir.exists()) {
			Logger.debug("Create storage dirs...");
			if(!fileWorkdir.mkdirs()) {
				Logger.err("Can't create work dirs.");
				throw new IOException();
			}
			Logger.info("Ok.");
		}
		Logger.debug("Open JDBC driver...");
		//2. открываем JDBC драйвер:
		Class.forName(dbdriver);
		connectionString = connectionPrefix+":"+dbType+":"+dbworkdir+dblockmode; 
		Logger.debug("Create new lead connection...");
		Logger.trace("Connection URL:\""+connectionString+"\"");
		singleConnection = DriverManager.getConnection(connectionString, dbuser, dbpass);
		Logger.debug("Ok");
		//3. инициализирем таблицы
		Logger.debug("Initialize tables...");
		SQLRequests.initInnerDbTables(singleConnection);
		Logger.debug("Ok");		
	}
	
	public void initStatsDB() throws IOException, SQLException, ClassNotFoundException {
		Logger.trace("Before you connect to Stats db: ");
		Logger.info("  1. Connect to db server as root like this: \"mysql -u root ...\".");
		Logger.info("  2. Create db for stats: \"CREATE DATABASE dbname;\".");
		Logger.info("  3. Create user for stats db: \"CREATE USER 'dbuser'@'localhost' IDENTIFIED BY 'dbpass';\".");
		Logger.info("  4. Add priviledges: \"GRANT ALL PRIVILEGES ON dbname.* TO 'dbuser'@'localhost' WITH GRANT OPTION;\".");
		Logger.info("  5. Update privileges: \"FLUSH PRIVILEGES;\".");
		Logger.info("  6. Write all parameters (dbname, dbhost, dbuser, dbpass) to server.conf file.");
		Logger.debug("Open JDBC driver...");
		Class.forName(statsDbdriver);
		//jdbc:mysql://repos.insttech.washington.edu:3306/johndoe
		statsConnectionString = statsConnectionPrefix+":"+statsDbType+"://"+statsDbhost+":"+statsDbport+"/"
			+statsDbname+"?user="+statsDbuser+"&password="+statsDbpass;
		Logger.debug("Create new lead connection for stats DB...");
		Logger.trace("Connection URL for stats DB:\""+statsConnectionString+"\"");
		statsSingleConnection = DriverManager.getConnection(statsConnectionString);
		Logger.debug("Ok");
		//3. инициализирем таблицы
		Logger.debug("Initialize tables...");
		SQLRequests.initStatsDbTables(statsSingleConnection);
		Logger.debug("Ok");		
	}


	public void init() throws IOException, SQLException, ClassNotFoundException {
		Logger.debug("Initialize inner DB...");
		initInnerDB();
		Logger.debug("Inner DB successfully inialized.");
		Logger.debug("Initialize stats DB...");
		initStatsDB();
		Logger.debug("Stats DB successfully inialized.");
	}
		
	public synchronized Connection getConnection() throws SQLException {
		Logger.debug("Try to create new database connection...");
		return DriverManager.getConnection(connectionString, dbuser, dbpass);
	}
	
	public synchronized Connection getStatsConnection() throws SQLException {
		Logger.debug("Try to create new database connection...");
		return DriverManager.getConnection(statsConnectionString);
	}
	
	@Override
	protected void finalize() throws Throwable {
		super.finalize();
		Logger.debug("Close inner DB lead connection...");
		singleConnection.close();
		Logger.debug("Ok.");
		Logger.debug("Close stats DB lead connection...");
		statsSingleConnection.close();
		Logger.debug("Ok.");
	}
	
}
