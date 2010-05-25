package com.iceberg.mp;

import java.util.ArrayList;
import java.util.List;

public class Env {
	
	private String name;
	
	private List<String> rules = new ArrayList<String>();
	
	public Env(List<String> rules, String name) {
		this.name = name;
		this.rules = rules;
	}
	
	private static List<String> parseRules(String pstring) {
		List<String> rlist = new ArrayList<String>();
		String[] srules  = pstring.split(","); 
		for(int i=0; i<srules.length; i++)
			rlist.add(srules[i]);
		return rlist;
	}
	
	public static Env deserEnv(String rules) {
		int nameEnd = rules.indexOf("@");
		String name = rules.substring(0,nameEnd);
		String srules = rules.substring(nameEnd+1,rules.length());
		List<String> rlist = parseRules(srules);
		return new Env(rlist,name);
	}
	
	public List<String> getRules() {
		return rules;
	}
}	
