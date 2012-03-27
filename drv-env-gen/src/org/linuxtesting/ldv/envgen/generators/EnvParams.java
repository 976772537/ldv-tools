/*
 * Copyright 2010-2012
 * Institute for System Programming, Russian Academy of Sciences (ISPRAS).
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package org.linuxtesting.ldv.envgen.generators;

import java.util.LinkedList;
import java.util.List;
import java.util.Properties;

import org.linuxtesting.ldv.envgen.Logger;


public abstract class EnvParams {
	public abstract String getStringId();	

	boolean sorted;
	boolean check;
	boolean init;
	boolean grouped;
	boolean genInterrupt = true;
	private boolean genTimers = true;
	
	public EnvParams(boolean sorted, boolean check, boolean init, boolean grouped) {
		super();
		this.check = check;
		this.sorted = sorted;
		this.init = init;
		this.grouped = grouped;
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
		
		String init = props.getProperty(key + ".init", "false");
		if(init.trim().equalsIgnoreCase("false")) {
			this.init = false;
		} else {
			this.init = true;
		}
		
		String grouped = props.getProperty(key + ".grouped", "true");
		if(grouped.trim().equalsIgnoreCase("false")) {
			this.grouped = false;
		} else {
			this.grouped = true;
		}
		
		String genInterrupt = props.getProperty(key + ".gen_interrupt", "true");
		if(genInterrupt.trim().equalsIgnoreCase("false")) {
			this.genInterrupt = false;
		} else {
			this.genInterrupt = true;
		}
		
		String genTimers = props.getProperty(key + ".gen_timers", "true");
		if(genTimers.trim().equalsIgnoreCase("false")) {
			this.genTimers = false;
		} else {
			this.genTimers = true;
		}
	}

	public boolean isSorted() {
		return sorted;
	}
	
	public boolean isCheck() {
		return check;
	}
	
	public boolean isInit() {
		return init;
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

	public boolean isGrouped() {
		return grouped;
	}

	public boolean isGenInterrupt() {
		return genInterrupt;
	}

	public boolean isGenTimers() {
		return genTimers;
	}
}
