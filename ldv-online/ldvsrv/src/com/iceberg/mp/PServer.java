package com.iceberg.mp;

import java.io.IOException;
import java.net.ServerSocket;
import java.net.SocketTimeoutException;
import java.nio.channels.IllegalBlockingModeException;
import java.util.ArrayList;
import java.util.List;


public class PServer extends Thread {
	
	
	public static void main(String[] args) {
		PServer server = new PServer();
		server.run();
	}
	
	public void run() {
        Config config = new Config();
        ServerSocket masterSocket = null;
        try {
                masterSocket = new ServerSocket(config.getPServerPort());
                List<PServerThread> threadList = new ArrayList<PServerThread>();
                while(true) {
                        PServerThread currentThread = new
                                PServerThread(masterSocket.accept(), new PServerProto());
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

