package com.iceberg.mp;

public class RunLDV {
	public static void main(String[] args) {
		// азпускаем сервер для веба
		Server server = new Server();
		// и сервер для клиентов
		PServer pserver = new PServer();
		// + schelduler (или дергает )
		
		server.start();
		pserver.start();
		
	}
}
