package com.iceberg.mp;

import java.sql.Connection;
import java.sql.SQLException;

import org.h2.jdbcx.JdbcDataSource;

public class SharedKitchen {
	public static void main(String[] args) throws SQLException {
		JdbcDataSource ds = new JdbcDataSource();
		ds.setURL("jdbc:h2:˜/test");
		ds.setUser("sa");
		ds.setPassword("sa");
		Connection conn = ds.getConnection();
		System.out.println(conn);
	}
}
