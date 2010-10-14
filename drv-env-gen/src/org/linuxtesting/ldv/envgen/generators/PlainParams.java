package org.linuxtesting.ldv.envgen.generators;

import java.util.Properties;

public class PlainParams extends EnvParams {
	
	public PlainParams(boolean check) {		
		super(true, check, false);
	}
	
	protected PlainParams(boolean sorted, boolean check, boolean init) {		
		super(sorted, check, init);
	}
	
	public PlainParams(Properties props, String key) {
		super(props, key);
	}

	@Override
	public String getStringId() {
		return "plain" + (sorted?"_sorted":"") + (check?"_withcheck":"");
	}
}
