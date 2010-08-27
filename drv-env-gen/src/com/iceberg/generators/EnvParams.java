package com.iceberg.generators;

public abstract class EnvParams {
	public abstract String getStringId();	

	boolean sorted;
	boolean check;
	
	public EnvParams(boolean sorted, boolean check) {
		super();
		this.check = check;
		this.sorted = sorted;
		assert !check || sorted : "if you want to check please sort it"; 
	}
	
	public boolean isSorted() {
		return sorted;
	}
	
	public boolean isCheck() {
		return check;
	}
}
