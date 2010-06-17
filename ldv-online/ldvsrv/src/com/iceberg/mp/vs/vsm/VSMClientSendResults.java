package com.iceberg.mp.vs.vsm;

import com.iceberg.mp.vs.VProtocol;
import com.iceberg.mp.vs.client.Result;

public class VSMClientSendResults extends VSMClient {

	private static final long serialVersionUID = 1L;
	
	private int id;
	private String presult = ""; 

	public String getStatus() {
		return presult;
	}
	
	public int getId() {
		return id;
	}

	public String getRresult() {
		return rresult;
	}

	public byte[] getReport() {
		return report;
	}

	public Result[] getResults() {
		return results;
	}

	private String rresult;
	private byte[] report;
	private Result[] results;
	
	public VSMClientSendResults(String name, String rresult, byte[] report, Result[] results, int id, String status) {
		super(VProtocol.sSendResults, name);
		this.id = id;
		this.rresult = rresult;
		this.report = report;
		this.results = results;
		this.presult = status;
	}
}
