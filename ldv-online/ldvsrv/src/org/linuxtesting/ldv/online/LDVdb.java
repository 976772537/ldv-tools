package org.linuxtesting.ldv.online;

import java.sql.SQLException;

import org.h2.tools.Server;

public class LDVdb {
	
	static Server hserver;
	
	public static void main(String[] args) {
		System.out.println("Starting H2 inner DB server...");
		try {
			hserver = Server.createTcpServer("-tcpAllowOthers").start();
		} catch (SQLException e) {
			e.printStackTrace();
			System.out.println("Can't start H2 server.");
			System.exit(1);
		}
		System.out.println("H2 database server successfully started with \"-tcpAllowOthers\" option.");
	}
	
}
