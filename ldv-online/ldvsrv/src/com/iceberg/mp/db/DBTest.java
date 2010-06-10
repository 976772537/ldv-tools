package com.iceberg.mp.db;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

import com.iceberg.mp.schelduler.Task;
public class DBTest {
	public static void main(String[] args) throws ClassNotFoundException, SQLException {
	/*	Class.forName("org.h2.Driver");
		Connection conn = DriverManager.getConnection(
				"jdbc:h2:/home/iceberg/ldvs/ldvs;LOCK_MODE=3", "test", "test");
		SQLRequests.initDb(conn);
		
		byte[] small = new byte[10040];
		SQLRequests.registerTask(conn, 1, small, Task.Status.TS_WAIT_FOR_VERIFICATION+"");*/
		
	}
	
}
