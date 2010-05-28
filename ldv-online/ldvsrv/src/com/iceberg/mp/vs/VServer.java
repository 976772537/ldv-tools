package com.iceberg.mp.vs;

import java.io.IOException;
import java.net.ServerSocket;
import java.net.Socket;
import java.net.SocketTimeoutException;
import java.nio.channels.IllegalBlockingModeException;

import com.iceberg.mp.Config;
import com.iceberg.mp.Scheduler;
import com.iceberg.mp.VerClient;

public class VServer extends Thread {
	
	private Scheduler scheduler;
	
	public VServer(Scheduler scheduler) {
		this.scheduler = scheduler;
	}
	
	public void run() {
        Config config = new Config();
        ServerSocket masterSocket = null;
        try {
                masterSocket = new ServerSocket(config.getVServerPort());
                while(true) {
                	Socket socket = masterSocket.accept();
                	VerClient vclient = new VerClient(socket);
                	scheduler.putVERClient(vclient);
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
                System.err.println("MASTER: Can't get port: " + config.getWServerPort());
                System.exit(1);
        } finally {
                try {
					masterSocket.close();
				} catch (IOException e) {
					e.printStackTrace();
				}
        }
	}
}

