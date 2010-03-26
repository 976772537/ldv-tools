package com.iceberg.generators.cmdstream;

import java.util.ArrayList;
import java.util.List;

public class CommandLD {
	private List<String> mains = new ArrayList<String>();
	
	public void addMain(String main) {
		mains.add(main);
	}
	
	public List<String> getMains() {
		return mains;
	}
}
