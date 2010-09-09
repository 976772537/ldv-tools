package com.iceberg.mp.vs.client;

import java.io.File;
import java.io.Serializable;

public class ClientInfo implements Serializable {

	private int availableProcessors;
	private long freeMemoryJVM;
	private long maxMemoryJVM;
	private long totalMemoryJVM;
	
	public ClientInfo() {
	    availableProcessors = Runtime.getRuntime().availableProcessors();
	   
	    /* Total amount of free memory available to the JVM */
	    freeMemoryJVM = Runtime.getRuntime().freeMemory();

	    /* This will return Long.MAX_VALUE if there is no preset limit */
	    /* Maximum amount of memory the JVM will attempt to use */
	    maxMemoryJVM = Runtime.getRuntime().maxMemory();

	    /* Total memory currently in use by the JVM */
	    totalMemoryJVM = Runtime.getRuntime().totalMemory();
	}
	
	public int getAvailableProcessors() {
		return availableProcessors;
	}

	public long getFreeMemoryJVM() {
		return freeMemoryJVM;
	}

	public long getMaxMemoryJVM() {
		return maxMemoryJVM;
	}

	public long getTotalMemoryJVM() {
		return totalMemoryJVM;
	}


}
