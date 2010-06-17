package com.iceberg.mp.vs.client;

import java.io.Serializable;

public class Result implements Serializable{
	
	public String getRresult() {
		return rresult;
	}

	public byte[] getReport() {
		return report;
	}

	private static final long serialVersionUID = 1L;
	private String rresult;
    private byte[] report;
    
    public Result(String rresult, byte[] report) {
    	this.rresult = rresult;
    	this.report = report;
    }
}
