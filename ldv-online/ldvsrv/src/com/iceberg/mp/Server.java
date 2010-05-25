package com.iceberg.mp;

import java.net.ServerSocket;
import java.net.SocketTimeoutException;

import java.util.ArrayList;
import java.util.List;

import java.nio.channels.IllegalBlockingModeException;

import java.lang.SecurityException;

import java.io.IOException;

public class Server extends Thread {
	
	public Scheduler scheduler;
	
	public Server(Scheduler scheduler) {
		
	}

	public void run() {
		Config config = new Config();
		ServerSocket masterSocket = null;
		try {
			masterSocket = new ServerSocket(config.getServerPort());
			List<ServerThread> threadList = new ArrayList<ServerThread>();
			while(true) {
				ServerThread currentThread = new 
					ServerThread(masterSocket.accept(), new ServerProto(), scheduler);
				threadList.add(currentThread);
				currentThread.start();
			}
		} catch(SocketTimeoutException e) {
			System.err.println("MASTER: SocketTimeoutException");
			System.exit(1);
		} catch(IllegalBlockingModeException e) {
			System.err.println("MASTER: IllegalBlockingModeException");
			System.exit(1);
		} catch(SecurityException e) {
			System.err.println("MASTER: Security exception");
			System.exit(1);
		} catch(IOException e) {
			System.err.println("MASTER: Can't get port: " + config.getServerPort());
			System.exit(1);
		} finally {
			try {
				masterSocket.close();
			} catch (IOException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
		}
	}
}
