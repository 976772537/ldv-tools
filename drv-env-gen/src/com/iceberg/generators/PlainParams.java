package com.iceberg.generators;

import java.util.Properties;

public class PlainParams extends EnvParams {
	
	public PlainParams(boolean check) {		
		super(true, check);
	}
	
	protected PlainParams(boolean sorted, boolean check) {		
		super(sorted, check);
	}
	
	public PlainParams(Properties props, String key) {
		super(props, key);
	}

	@Override
	public String getStringId() {
		return "plain" + (sorted?"_sorted":"") + (check?"_withcheck":"");
	}
}
