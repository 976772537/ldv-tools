package com.iceberg.mp.server;

import java.io.BufferedInputStream;
import java.io.BufferedOutputStream;
import java.io.IOException;
import java.net.Socket;

import com.iceberg.mp.Logger;
import com.iceberg.mp.server.protocol.ServerProtocolInterface;

public class ServerThread extends Thread implements ServerThreadInterface {
	
	protected ServerConfig config;
	protected Socket socket;
	protected ServerProtocolInterface protocol;

	public ServerThread(ServerConfig config, Socket socket) {
		this.config = config;
		this.socket = socket;
	}

	public void run() {
		Logger.info(socket.getInetAddress()+": Start client connection.");
		BufferedInputStream in = null;
		BufferedOutputStream out = null;
		try {
			in = new BufferedInputStream( socket.getInputStream());
			out = new BufferedOutputStream( socket.getOutputStream());			
			protocol.communicate(config, in, out);
		} catch(IOException e) {
			e.printStackTrace();
		} catch(Throwable e) {
			e.printStackTrace();
		} finally {
			try {
				in.close();
				out.close();
				socket.close();
			} catch (IOException e) {
				e.printStackTrace();
			}
		}
		Logger.info(": Close client connection.");
	}
	
}
