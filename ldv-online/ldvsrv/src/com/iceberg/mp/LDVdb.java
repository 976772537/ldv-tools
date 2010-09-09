package com.iceberg.mp;

import java.sql.SQLException;

import org.h2.tools.Server;

public class LDVdb {
	
	public static void main(String[] args) {
		System.out.println("Starting H2 inner DB server...");
		Server h2server = null;
		try {
			h2server = Server.createTcpServer("-tcpAllowOthers").start();
		} catch (SQLException e) {
			e.printStackTrace();
			System.out.println("Can't start H2 server.");
			System.exit(1);
		}
		System.out.println("H2 database server successfully started with \"-tcpAllowOthers\" option.");
	}
	
}
