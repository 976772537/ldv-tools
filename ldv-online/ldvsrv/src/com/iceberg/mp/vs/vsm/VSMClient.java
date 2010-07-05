package com.iceberg.mp.vs.vsm;

public class VSMClient extends VSM {

	private static final long serialVersionUID = 1L;
	private String name;

	public VSMClient(String text, String name) {
		super(text);
		this.name = name;
	}
	
	public String getName() {
		return name;
	}

}
