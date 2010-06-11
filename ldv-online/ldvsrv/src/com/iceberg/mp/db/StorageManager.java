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
	
	private String dbuser;
	private String dbpass;
	
	private static final String connectionPrefix = "jdbc";
	private static final String dbType = "h2";
	private static final String dbdriver = "org.h2.Driver";
	private static final String dblockmode = ";LOCK_MODE=3;AUTO_SERVER=TRUE";
	
	private String connectionString;
	
	private Connection singleConnection;
	
	public String getBins() {
		return this.bins;
	}
	
	public StorageManager(Map<String, String> params) {
		this.workdir = params.get("WorkDir");
		this.dbworkdir = workdir+"/db";
		this.bins = workdir+"/bins";
		this.dbuser = params.get("DBUser");
		this.dbpass = params.get("DBPass");
	}

	public void init() throws IOException, SQLException, ClassNotFoundException {
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
		SQLRequests.initDb(singleConnection);
		Logger.debug("Ok");
	}
	
	public void init_test() throws IOException, SQLException, ClassNotFoundException {
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
		Class.forName("org.h2.Driver");
		connectionString = connectionPrefix+":"+dbType+":"+dbworkdir; 
		Logger.debug("Create new lead connection...");
		Logger.trace("Connection URL:\""+connectionString+"\"");
		singleConnection = DriverManager.getConnection(connectionString, dbuser, dbpass);
		Logger.debug("Ok");
	}

	
	
	public synchronized Connection getConnection() throws SQLException {
		Logger.debug("Try to create new database connection...");
		return DriverManager.getConnection(connectionString, dbuser, dbpass);
	}
	
	public void close() throws SQLException {
		//1. закрываем все соеждинения
		Logger.info("Close lead connection...");
		singleConnection.close();
		Logger.info("Ok");
	}

	@Override
	protected void finalize() throws Throwable {
		super.finalize();
		singleConnection.close();
	}
	
}
