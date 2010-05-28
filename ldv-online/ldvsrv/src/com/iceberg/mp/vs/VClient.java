package com.iceberg.mp.vs;

import java.net.Socket;

import java.io.IOException;
import java.io.ObjectInputStream;

import com.iceberg.mp.Config;

public class VClient {

	public static void main(String[] args) throws IOException {
		Config config = new Config();
		//PClientProto protocol = new PClientProto();
		Socket socket = new Socket(config.getServerName(), config.getVServerPort());

		ObjectInputStream ois = new ObjectInputStream(socket.getInputStream());
		System.out.println("Ok");
		socket.close();
	}
}
