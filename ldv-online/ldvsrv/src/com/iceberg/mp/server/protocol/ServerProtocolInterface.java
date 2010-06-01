package com.iceberg.mp.server.protocol;

import java.io.InputStream;
import java.io.OutputStream;

import com.iceberg.mp.server.ServerConfig;

public interface ServerProtocolInterface {
	public void communicate(ServerConfig config, InputStream in, OutputStream out);
}
