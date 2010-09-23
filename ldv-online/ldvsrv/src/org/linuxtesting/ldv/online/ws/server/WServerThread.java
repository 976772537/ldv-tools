package org.linuxtesting.ldv.online.ws.server;

import java.net.Socket;

import org.linuxtesting.ldv.online.server.ServerConfig;
import org.linuxtesting.ldv.online.server.ServerThread;

public class WServerThread extends ServerThread {
	
	public WServerThread(ServerConfig config, Socket socket) {
		super(config, socket);
		protocol = new WServerProtocol();
	}

}
