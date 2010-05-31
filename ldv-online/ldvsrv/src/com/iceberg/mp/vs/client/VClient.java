package com.iceberg.mp.vs.client;

import java.net.Socket;

import java.io.IOException;

import com.iceberg.mp.server.ClientConfig;

public class VClient {

	public static void main(String[] args) throws IOException {
		ClientConfig config = new ClientConfig("localhost",1111,"unique");
		Socket socket = new Socket(config.getServerName(), config.getServerPort());
		VClientProtocol protocol = new VClientProtocol();
		protocol.communicate(config.getCientName(),socket.getInputStream(),socket.getOutputStream());
		socket.close();
	}
}
