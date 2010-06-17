package com.iceberg.mp.schelduler;

import java.util.ArrayList;
import java.util.List;

public class Env {
	
	private String name;
	
	//private List<String> rules = new ArrayList<String>();
	private List<Rule> rules = new ArrayList<Rule>();
	
	// вынести отсюда статические методы - так как класс будет
	// передоваться как сообщение
	public Env(List<Rule> rules, String name) {
		this.name = name;
		this.rules = rules;
	}
	
	public List<Rule> getRules() {
		return rules;
	}
	
	public String getName() {
		return name;
	}
}	
