package com.iceberg.mp;

import java.net.Socket;

import java.io.BufferedInputStream;
import java.io.BufferedOutputStream;
import java.io.ObjectInputStream;

import java.io.IOException;

public class Client {

	public static void main(String[] args) throws IOException {
		Config config = new Config();
		PClientProto protocol = new PClientProto();
		Socket socket = new Socket(config.getServerName(), config.getPServerPort());

		ObjectInputStream ois = new ObjectInputStream(socket.getInputStream());
		System.out.println("Ok");
		socket.close();
	}
}
