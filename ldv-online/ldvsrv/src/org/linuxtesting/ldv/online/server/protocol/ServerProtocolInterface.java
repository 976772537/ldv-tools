package org.linuxtesting.ldv.online.server.protocol;

import java.io.InputStream;
import java.io.OutputStream;

import org.linuxtesting.ldv.online.server.ServerConfig;

public interface ServerProtocolInterface {
	public void communicate(ServerConfig config, InputStream in, OutputStream out);
}
