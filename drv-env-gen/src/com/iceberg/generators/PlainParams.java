package com.iceberg.generators;

public class PlainParams extends EnvParams {
	
	public PlainParams(boolean check) {		
		super(true, check);
	}
	
	protected PlainParams(boolean sorted, boolean check) {		
		super(sorted, check);
	}
	
	@Override
	public String getStringId() {
		return "plain" + (sorted?"_sorted":"") + (check?"_withcheck":"");
	}
}
