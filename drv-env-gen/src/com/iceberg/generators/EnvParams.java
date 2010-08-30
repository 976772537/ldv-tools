package com.iceberg.generators;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.LinkedList;
import java.util.List;
import java.util.Properties;

import com.iceberg.Logger;

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
	
	public static EnvParams[] loadParameters(String fileName) {
		Properties props = new Properties(); 
		loadFile(props, fileName, null);
		
		List<EnvParams> res = new LinkedList<EnvParams>();
		
		String val = props.getProperty(CONFIG_LIST);
		if(val!=null) {
			String[] plist = val.split(",");
			for(String cf : plist) {
				String key = cf.trim();
				String type = props.getProperty(key + "." + "type");
				if(type!=null && !type.isEmpty()) {
					String t = type.trim();
					if(t.equals("PlainParams")) {
						PlainParams p = new PlainParams(props, key);
						Logger.debug("Adding plain parameters " + p);
					} else if(t.equals("SequenceParams")) {
						SequenceParams p = new SequenceParams(props, key);
						Logger.debug("Adding sequence parameters " + p);
					} else {
						Logger.warn("Unknown type of parameters " + type);
					}
				} else {
					Logger.warn("Empty type of parameters " + type);					
				}
			}
		}
		
		return res.toArray(new EnvParams[0]);
		
	}
	
	private static boolean loadFile(Properties prop, String fileName, Class<?> codeBase) {
		InputStream is = null;
		
		try {
	    	File f = new File(fileName);
	    	if (f.exists()) {
	    		is = new FileInputStream(f);
	    	} else {
	    		// try to load as a resource (from jar)
	    		Class<?> clazz = (codeBase != null) ? codeBase : EnvParams.class;
	    		is = clazz.getResourceAsStream(fileName);
	    	}

	    	if (is != null) {
	    		prop.load(is);
	    		is.close();
	    		return true;
	    	}
		} catch (IOException iex) {
			return false;
		}
		return false;
	}
}
