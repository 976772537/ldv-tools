package com.iceberg.mp.vs.vsm;

import com.iceberg.mp.vs.VProtocol;

public class VSMClientSendResults extends VSMClient {

	private static final long serialVersionUID = 1L;
	
	private int id;
	private String status;

	public String getStatus() {
		return status;
	}
	
	public int getId() {
		return id;
	}

	public VSMClientSendResults(String name, int id, String status) {
		super(VProtocol.sSendResults, name);
		this.id = id;
		this.status = status;
	}
}
