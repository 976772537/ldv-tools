package com.iceberg.generators;

public class PlainParams extends EnvParams {
	boolean sorted;
	public PlainParams(boolean sorted, boolean check) {		
		super(check);
		this.sorted = sorted;
		assert !check || sorted : "if you want to check please sort it"; 
	}
	public boolean isSorted() {
		return sorted;
	}
	@Override
	public String getStringId() {
		return "plain" + (sorted?"_sorted":"") + (check?"_withcheck":"");
	}
}
