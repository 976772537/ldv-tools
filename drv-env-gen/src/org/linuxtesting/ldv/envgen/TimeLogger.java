package org.linuxtesting.ldv.envgen;

public class TimeLogger {
	
	private long start = 0;
	private String signature = null;
	
	public TimeLogger(String signature) {
		this.signature = signature;
		TimeLogger.putMsg("ENTER: " + this.signature + '\n');
		this.start = System.currentTimeMillis();
	}
	
	public void putDown() {
		long end = System.currentTimeMillis();
		TimeLogger.putMsg("EXIT : " + this.signature + "\nTIME :" + (end - this.start) +"ms\n");
	}
	
	private static void putMsg(String msg) {
		Logger.info(msg);
	}
}
