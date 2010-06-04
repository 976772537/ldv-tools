package com.iceberg.generators;

import com.iceberg.Logger;

public class MainGeneratorThread implements Runnable {
	
	protected String filename;
	
	
	public MainGeneratorThread(String filename) {
		super();
		this.filename = filename;
	}
	
	public void run() {
		Logger.info("MGEN_THREAD_START: " +filename);
		MainGenerator.generate(this.filename);
	}
	
}
