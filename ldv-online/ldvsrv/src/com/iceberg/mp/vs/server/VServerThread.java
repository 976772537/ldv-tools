package com.iceberg.mp.vs.server;

import java.net.Socket;

import com.iceberg.mp.server.ServerConfig;
import com.iceberg.mp.server.ServerThread;

public class VServerThread extends ServerThread {

	public VServerThread(ServerConfig config, Socket socket) {
		super(config, socket);
		protocol = new VServerProtocol();
	}

}
