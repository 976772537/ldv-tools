package com.iceberg.mp.ws;

import java.io.BufferedInputStream;
import java.io.BufferedOutputStream;
import java.io.IOException;

import java.net.Socket;

import com.iceberg.mp.RunLDV;
import com.iceberg.mp.Scheduler;

public class WServerThread extends Thread {
	
	private Socket socket;
	private WServerProto protocol;
	private Scheduler scheduler;

	public WServerThread(Socket socket, WServerProto protocol, Scheduler scheduler) {
		this.socket = socket;
		this.protocol = protocol;
		this.scheduler =  scheduler;
	}

	public void run() {
		RunLDV.log.info("WS: Start client connection.");
		BufferedInputStream in = null;
		BufferedOutputStream out = null;
		try {
			in = new BufferedInputStream( socket.getInputStream());
			out = new BufferedOutputStream( socket.getOutputStream());
			protocol.Communicate(in, out, scheduler);
		} catch(IOException e) {
			System.err.println("I/O Exception.");
		} finally {
			try {
				in.close();
				out.close();
				socket.close();
			} catch (IOException e) {
				e.printStackTrace();
			}
		}
		RunLDV.log.info("WS: Close client connection.");
	}

}
