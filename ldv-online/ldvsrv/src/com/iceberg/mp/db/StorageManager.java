package com.iceberg.mp.db;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.Map;

import com.iceberg.mp.RunLDV;
import java.io.File;
import java.io.IOException;

public class StorageManager {

	
	private static final String SQLINITREQUEST_1 = "CREATE CACHED TABLE " +
		"IF NOT EXISTS CLIENTS(id INT PRIMARY KEY AUTO_INCREMENT, " +
		"name VARCHAR(255) NOT NULL, status VARCHAR(255) NOT NULL)";
	// path  не нужен, путь формируется как bins+id
	private static final String SQLINITREQUEST_2 = "CREATE CACHED TABLE " +
		"IF NOT EXISTS TASKS(id INT PRIMARY KEY, " +
		"id_mtasks INT, id_user INT NOT NULL, vparams VARCHAR(255) NOT NULL, status VARCHAR(255) NOT NULL)";
	private static final String SQLINITREQUEST_3 = "CREATE CACHED TABLE " +
		"IF NOT EXISTS USERS(id INT PRIMARY KEY AUTO_INCREMENT, " +
		"privileges INT NOT NULL, name VARCHAR(255) NOT NULL)";

	
	private String workdir;
	private String dbworkdir;
	private String bins;
	
	private String dbname;
	private String dbuser;
	private String dbpass;
	
	private int dbconnections;
	
	private static final String dbtype = "h2";
	
	private static final String connectionPrefix = "jdbc";
	private static final String dbType = "h2";
	private static final String dbdriver = "org.h2.Driver";
	
	private String connectionString;
	
	private Connection singleConnection;
	
	public String getBins() {
		return this.bins;
	}
	
	public StorageManager(Map<String, String> params) {
		this.workdir = params.get("WorkDir");
		this.dbworkdir = workdir+"/db";
		this.bins = workdir+"/bins";
		this.dbname = params.get("DBName");
		this.dbuser = params.get("DBUser");
		this.dbpass = params.get("DBPass");
		this.dbconnections = Integer.valueOf(params.get("DBConnections"));
	}

	public void init() throws IOException, SQLException, ClassNotFoundException {
		//1. создаем директории, если их нет
		File fileWorkdir = new File(bins);
		if(!fileWorkdir.exists()) {
			RunLDV.log.info("Create storage dirs...");
			if(!fileWorkdir.mkdirs()) {
				RunLDV.log.info("Can't create work dirs.");
				throw new IOException();
			}
			RunLDV.log.info("Ok.");
		}
		RunLDV.log.info("Open JDBC driver...");
		//2. открываем JDBC драйвер:
		Class.forName("org.h2.Driver");
		connectionString = connectionPrefix+":"+dbType+":"+dbworkdir; 
		RunLDV.log.info("Create new lead connection...");
		singleConnection = DriverManager.getConnection(connectionString, dbuser, dbpass);
		RunLDV.log.info("Ok");
		//3. инициализирем таблицы
		RunLDV.log.info("Initialize tables...");
		Statement st = singleConnection.createStatement();
		st.execute("DROP TABLE IF EXISTS CLIENTS");
		st.execute(SQLINITREQUEST_1);
		st.execute(SQLINITREQUEST_2);
		st.execute(SQLINITREQUEST_3);
		st.close();
		RunLDV.log.info("Ok");
	}
	
	public synchronized Connection getConnection() throws SQLException {
		RunLDV.log.info("Try to create new database connection...");
		return DriverManager.getConnection(connectionString, dbuser, dbpass);
	}
	
	public void close() throws SQLException {
		//1. закрываем все соеждинения
		RunLDV.log.info("Close lead connection...");
		singleConnection.close();
		RunLDV.log.info("Ok");
	}

	@Override
	protected void finalize() throws Throwable {
		super.finalize();
		singleConnection.close();
	}
	

}
