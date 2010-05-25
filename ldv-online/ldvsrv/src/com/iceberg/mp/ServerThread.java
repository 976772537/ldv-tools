package com.iceberg.mp;

import java.io.BufferedInputStream;
import java.io.BufferedOutputStream;
import java.io.IOException;

import java.net.Socket;

public class ServerThread extends Thread {
	
	private Socket socket;
	private ServerProto protocol;
	private Scheduler scheduler;

	public ServerThread(Socket socket, ServerProto protocol, Scheduler scheduler) {
		this.socket = socket;
		this.protocol = protocol;
		this.scheduler =  scheduler;
	}

	public void run() {
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
			}
		}
	}

}
