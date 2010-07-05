package com.iceberg.mp.schelduler;

import java.util.ArrayList;
import java.util.List;

public class Env {
	
	private String name;
	
	private List<String> rules = new ArrayList<String>();
	
	public Env(List<String> ruleList, String name) {
		this.rules = ruleList;
		this.name = name;
	}

	public List<String> getRules() {
		return rules;
	}
	
	public String getName() {
		return name;
	}
}	
