package com.iceberg.mp.server;

import java.net.Socket;

import com.iceberg.mp.Logger;
import com.iceberg.mp.vs.server.VServerThread;
import com.iceberg.mp.ws.server.WServerThread;

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
