package org.linuxtesting.ldv.online.server;

import java.net.Socket;

import org.linuxtesting.ldv.online.Logger;
import org.linuxtesting.ldv.online.vs.server.VServerThread;
import org.linuxtesting.ldv.online.ws.server.WServerThread;

public class ServerThreadFactory {
	public static ServerThreadInterface create(ServerConfig config, Socket socket) {
		if(config.getServerType().equals(ServerThreadEnum.WS))
			return new WServerThread(config, socket);
		if(config.getServerType().equals(ServerThreadEnum.VS))
			return new VServerThread(config, socket);
		Logger.err("Unknown server type.");
		return null;
	}
}
