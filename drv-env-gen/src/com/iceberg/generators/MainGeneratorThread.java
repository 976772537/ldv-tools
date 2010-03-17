package com.iceberg.generators;

public class MainGeneratorThread implements Runnable {
	
	protected String filename;
	
	
	public MainGeneratorThread(String filename) {
		super();
		this.filename = filename;
	}
	
	public void run() {
		System.out.println("MGEN_THREAD_START: " +filename);
		MainGenerator.generate(this.filename);
	}
	
}
