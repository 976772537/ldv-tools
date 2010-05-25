package com.iceberg.mp;

import java.net.Socket;

public class VerClient extends Thread {
	
	private Socket socket;
	
	private static enum Status {
		VS_WAIT_FOR_TASK,
		VS_HAVE_TASKS
	}

	private volatile Status status = Status.VS_WAIT_FOR_TASK;

	public Status getStatus() {
		return status; 
	}

	public VerClient(Socket socket) {
		this.socket = socket;
	}

	public String getVName() {
		return socket.getInetAddress().toString();
	}
}	
