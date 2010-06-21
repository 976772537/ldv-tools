package com.iceberg.mp.ws.wsm;

public class WSMLdvtowsResponse extends WSM {
	private final static String tagB_result = "<result>";
	private final static String tagE_result = "</result>";
	
	public String result = "OK";
	
	public void setResult(String result) {
		this.result = result;
	}
	
	public String toWSXML() {
		return super.toWSXML(tagB_result+result+tagE_result);
	}
	
	public String toWSXML(String msg) {
		return super.toWSXML(tagB_result+result+tagE_result+msg);
	}
}
