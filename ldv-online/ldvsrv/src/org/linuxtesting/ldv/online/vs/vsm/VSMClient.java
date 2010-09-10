package org.linuxtesting.ldv.online.vs.vsm;

import org.linuxtesting.ldv.online.vs.client.ClientInfo;

public class VSMClient extends VSM {
	
	private ClientInfo clientInfo;
	private static final long serialVersionUID = 1L;
	private String name;

	public VSMClient(String text, String name) {
		super(text);
		this.name = name;
		this.clientInfo = new ClientInfo();
	}
	
	public String getName() {
		return name;
	}
	
	public ClientInfo getClientInfo() {
		return clientInfo;
	}

}
