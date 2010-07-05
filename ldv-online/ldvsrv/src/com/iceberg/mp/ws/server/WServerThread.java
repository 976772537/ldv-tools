package com.iceberg.mp.ws.server;

import java.net.Socket;

import com.iceberg.mp.server.ServerConfig;
import com.iceberg.mp.server.ServerThread;

public class WServerThread extends ServerThread {
	
	public WServerThread(ServerConfig config, Socket socket) {
		super(config, socket);
		protocol = new WServerProtocol();
	}

}
