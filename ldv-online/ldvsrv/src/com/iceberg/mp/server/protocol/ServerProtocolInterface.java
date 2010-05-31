package com.iceberg.mp.server.protocol;

import java.io.InputStream;
import java.io.OutputStream;

import com.iceberg.mp.schelduler.Scheduler;

public interface ServerProtocolInterface {
	public void communicate(Scheduler scheduler, InputStream in, OutputStream out);
}
