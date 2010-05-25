package com.iceberg.mp;

import java.net.Socket;

import java.io.BufferedInputStream;
import java.io.BufferedOutputStream;

import java.io.IOException;

public class Client {

	public static void main(String[] args) throws IOException {
		Config config = new Config();
		PClientProto protocol = new PClientProto();
		Socket puppetSocket = null;
		puppetSocket = new Socket(config.getServerName(), config.getPServerPort());
		BufferedInputStream in = new BufferedInputStream(puppetSocket.getInputStream());
		BufferedOutputStream out = new BufferedOutputStream(puppetSocket.getOutputStream());

		protocol.Communicate(in,out);

		in.close();
		out.close();
		puppetSocket.close();
	}
}
