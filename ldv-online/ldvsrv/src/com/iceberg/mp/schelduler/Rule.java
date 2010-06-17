package com.iceberg.mp.schelduler;

import java.util.List;
import com.iceberg.mp.vs.client.Result;

public class Rule {

	private int id;
	private String name;
	private List<Result> results;
	
	public Rule(int id, List<Result> results) {
		this.id = id;
		this.results = results;
	}
	
	public Rule(int id, List<Result> results, String name) {
		this.id = id;
		this.results = results;
		this.name = name;
	}
	
	public List<Result> getReLists() {
		return results;
	}
	
	public int getId() {
		return id;
	}
	
	public Rule(String name) {
		this.name = name;
	}
	
	public String getName() {
		return name;
	}

}
