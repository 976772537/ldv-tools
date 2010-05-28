package com.iceberg.mp.ws;

import java.io.IOException;
import java.net.ServerSocket;
import java.net.SocketTimeoutException;
import java.nio.channels.IllegalBlockingModeException;
import java.util.ArrayList;
import java.util.List;

import com.iceberg.mp.Config;
import com.iceberg.mp.RunLDV;
import com.iceberg.mp.Scheduler;

public class WServer extends Thread {
	
	public Scheduler scheduler;
	
	public WServer(Scheduler scheduler) {
		this.scheduler = scheduler;
	}

	public void run() {
		RunLDV.log.info("WS: Start main thread.");
		Config config = new Config();
		ServerSocket masterSocket = null;
		try {
			masterSocket = new ServerSocket(config.getWServerPort());
			List<WServerThread> threadList = new ArrayList<WServerThread>();
			while(true) {
				WServerThread currentThread = new 
					WServerThread(masterSocket.accept(), new WServerProto(), scheduler);
				threadList.add(currentThread);
				currentThread.start();
			}
		} catch(SocketTimeoutException e) {
			RunLDV.log.info("WS: SocketTimeoutException.");
			System.exit(1);
		} catch(IllegalBlockingModeException e) {
			RunLDV.log.info("WS: IllegalBlockingModeException.");
			System.exit(1);
		} catch(SecurityException e) {
			RunLDV.log.info("WS: Security exception");
			System.err.println("MASTER: Security exception");
			System.exit(1);
		} catch(IOException e) {
			RunLDV.log.info("WS: Can't get port: " + config.getWServerPort());
			System.exit(1);
		} finally {
			try {
				masterSocket.close();
			} catch (IOException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
		}
		RunLDV.log.info("WS: End main thread.");
	}
}
