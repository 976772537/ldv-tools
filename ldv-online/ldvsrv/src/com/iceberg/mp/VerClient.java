package com.iceberg.mp;

import java.net.Socket;

public class VerClient extends Thread {
	
	private Socket socket;
	
	private static enum Status {
		VS_WAIT_FOR_TASK,
		VS_HAVE_TASKS
	}

	private Status status = Status.VS_WAIT_FOR_TASK;

	public synchronized getStatus() {
		return status; 
	}
	
	public VerClient(Socket socket) {
		this.socket = socket;
	}
}	
