package org.linuxtesting.ldv.online.vs.server;

import java.net.Socket;

import org.linuxtesting.ldv.online.server.ServerConfig;
import org.linuxtesting.ldv.online.server.ServerThread;

public class VServerThread extends ServerThread {

	public VServerThread(ServerConfig config, Socket socket) {
		super(config, socket);
		protocol = new VServerProtocol();
	}

}
