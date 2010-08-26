package com.iceberg.generators;

public abstract class EnvParams {
	public abstract String getStringId();	

	boolean check;
	
	public EnvParams(boolean check) {
		super();
		this.check = check;
	}
	
	public boolean isCheck() {
		return check;
	}
}
