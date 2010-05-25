package com.iceberg.mp;

public class RunLDV {
	public static void main(String[] args) {
		// создаем планировщик
		Scheduler scheduler = new Scheduler();
		// создаем сервер для веба
		Server server = new Server(scheduler);
		// и сервер для клиентов
		PServer pserver = new PServer(scheduler);

		scheduler.start();
		server.start();
		pserver.start();
		
	}
}
