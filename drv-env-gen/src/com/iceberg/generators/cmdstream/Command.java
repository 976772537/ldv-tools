package com.iceberg.generators.cmdstream;

import java.util.ArrayList;
import java.util.List;

public class Command {
	private List<String> opts = new ArrayList<String>();
	private List<String> in = new ArrayList<String>();
	private List<String> out = new ArrayList<String>();
	
	public void addOpt(String opt) {
		opts.add(opt);
	}
	
	public void addIn(String in) {
		opts.add(in);
	}
	
	public void addOut(String out) {
		opts.add(out);
	}

	public List<String> getOpts() {
		return opts;
	}
	
	public List<String> getIn() {
		return opts;
	}
	
	public List<String> getOut() {
		return opts;
	}
}
