package org.linuxtesting.ldv.online.server;

import java.io.IOException;
import java.net.ServerSocket;
import java.net.SocketTimeoutException;
import java.nio.channels.IllegalBlockingModeException;
import java.util.ArrayList;
import java.util.List;

import org.linuxtesting.ldv.online.Logger;

public class Server extends Thread {
	protected ServerConfig config;
	
	public Server(ServerConfig config) {
		this.config = config;
	}
	
	public void run() {
		ServerSocket masterSocket = null;
		try {
			masterSocket = new ServerSocket(config.getServerPort());
			List<ServerThreadInterface> threadList = new ArrayList<ServerThreadInterface>();
			while(true) {
				ServerThreadInterface currentThread = ServerThreadFactory.create(config, masterSocket.accept());
				threadList.add(currentThread);
				currentThread.start();
			}
		} catch(SocketTimeoutException e) {
			Logger.err("SocketTimeoutException.");
			System.exit(1);
		} catch(IllegalBlockingModeException e) {
			Logger.err("IllegalBlockingModeException.");
			System.exit(1);
		} catch(SecurityException e) {
			Logger.err("Security exception");
			System.exit(1);
		} catch(IOException e) {
			Logger.err("Can't get port: " + config.getServerPort());
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
