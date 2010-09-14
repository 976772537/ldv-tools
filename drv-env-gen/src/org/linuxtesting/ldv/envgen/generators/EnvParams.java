package org.linuxtesting.ldv.envgen.generators;

import java.util.LinkedList;
import java.util.List;
import java.util.Properties;

import org.linuxtesting.ldv.envgen.Logger;


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
	
	public EnvParams(Properties props, String key) {
		String sorted = props.getProperty(key + ".sorted", "true");
		if(sorted.trim().equalsIgnoreCase("false")) {
			this.sorted = false;
		} else {
			this.sorted = true;
		}
		
		String check = props.getProperty(key + ".check", "true");
		if(check.trim().equalsIgnoreCase("false")) {
			this.check = false;
		} else {
			this.check = true;
		}
	}

	public boolean isSorted() {
		return sorted;
	}
	
	public boolean isCheck() {
		return check;
	}
	
	final static String CONFIG_LIST = "include";
	
	public static EnvParams[] loadParameters(Properties props) {
		List<EnvParams> res = new LinkedList<EnvParams>();
		
		String val = props.getProperty(CONFIG_LIST);
		if(val==null || val.trim().isEmpty()) {
			Logger.warn("Configurations list is empty " + val);
			return null;
		}
		String[] plist = val.split(",");
		for(String cf : plist) {
			String key = cf.trim();
			String type = props.getProperty(key + "." + "type");
			if(type!=null && !type.isEmpty()) {
				String t = type.trim();
				if(t.equals("PlainParams")) {
					PlainParams p = new PlainParams(props, key);
					res.add(p);
					Logger.debug("Adding plain parameters " + p);
				} else if(t.equals("SequenceParams")) {
					SequenceParams p = new SequenceParams(props, key);
					res.add(p);
					Logger.debug("Adding sequence parameters " + p);
				} else {
					Logger.warn("Unknown type of parameters " + type);
				}
			} else {
				Logger.warn("Empty type of parameters " + type);					
			}
		}
		
		return res.toArray(new EnvParams[0]);
		
	}
	
	@Override
	public String toString() {
		return getStringId();
	}
}
