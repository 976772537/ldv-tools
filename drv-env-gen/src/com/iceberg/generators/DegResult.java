package com.iceberg.generators;

import java.util.Arrays;
import java.util.LinkedList;
import java.util.List;

public class DegResult {

	boolean result;
	List<String> mains = new LinkedList<String>();
	
	public DegResult(boolean b) {
		this.result = false;
	}

	public DegResult(List<String> mains) {
		this.result = true;
		this.mains.addAll(mains);
	}
	
	public DegResult(String... ids) {
		this.result = true;
		mains.addAll(Arrays.asList(ids));
	}

	public boolean isSuccess() {
		return result;
	}

	public List<String> getMains() {
		return mains;
	}

}
