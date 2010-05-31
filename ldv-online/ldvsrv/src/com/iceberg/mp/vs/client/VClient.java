package com.iceberg.mp.vs.client;

import java.net.Socket;
import java.util.Map;

import java.io.IOException;

import com.iceberg.mp.server.ClientConfig;
import com.iceberg.mp.server.Config;
import com.iceberg.mp.server.ServerThreadEnum;

public class VClient {

	public static void main(String[] args) throws IOException {
		Map<String,String> params = Config.readParameters(args[0]);
		ClientConfig config = new ClientConfig(params, ServerThreadEnum.VS);
		Socket socket = new Socket(config.getServerName(), config.getServerPort());
		VClientProtocol protocol = new VClientProtocol();
		protocol.communicate(config.getCientName(),socket.getInputStream(),socket.getOutputStream());
		socket.close();
	}
}
