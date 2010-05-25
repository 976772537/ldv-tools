package com.iceberg.mp;

import java.io.IOException;
import java.net.ServerSocket;
import java.net.Socket;
import java.net.SocketTimeoutException;
import java.nio.channels.IllegalBlockingModeException;

public class PServer extends Thread {
	
	private Scheduler scheduler;
	
	public PServer(Scheduler scheduler) {
		this.scheduler = scheduler;
	}
	
	public void run() {
        Config config = new Config();
        ServerSocket masterSocket = null;
        try {
                masterSocket = new ServerSocket(config.getPServerPort());
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
                System.err.println("MASTER: Can't get port: " + config.getServerPort());
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

