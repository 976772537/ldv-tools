package org.linuxtesting.ldv.envgen.generators.tests;

import org.linuxtesting.ldv.envgen.Logger;
import org.linuxtesting.ldv.envgen.generators.MainGenerator;

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
