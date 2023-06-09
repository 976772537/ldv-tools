/*
 * Copyright (C) 2010-2012
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
package org.linuxtesting.ldv.csd.utils;

import java.lang.NumberFormatException;

public class Logger {
	public static int logLevel = 10;
	public static String name = "Logger";
	
	public static enum Type {
		WARNING,
		ERROR,
		INFO,
		TRACE,
		NORMAL,
		DEBUG,
		ALL
	}

	public static void getLogLevelFromEnv() {
		String stringLogLevel = System.getenv("LDV_DEBUG");
		if(stringLogLevel==null || stringLogLevel.length()==0) {
			warn("LDV_DEBUG variable not set. Usinig default log level - 10.");
		} else {
			try {
				logLevel = Integer.valueOf(stringLogLevel);
			} catch (NumberFormatException e) {
				warn("LDV_DEBUG variable have wrong format. Usinig default log level - 10.");	
			}
		}
	}
	
	public static void warn(String msg) {
		printByType(Type.WARNING, msg);
	}
	
	public static void err(String msg) {
		printByType(Type.ERROR, msg);
	}
	
	public static void info(String msg) {
		printByType(Type.INFO, msg);
	}
	
	public static void norm(String msg) {
		printByType(Type.NORMAL, msg);
	}
	
	public static void debug(String msg) {
		printByType(Type.DEBUG, msg);
	}
	
	public static void trace(String msg) {
		printByType(Type.TRACE, msg);
	}
	
	public static void all(String msg) {
		printByType(Type.ALL, msg);
	}
	
	public static void printByType(Type type, String msg) {
		if(type.equals(Type.ERROR))
			log("ERROR: "+ msg);
		else if(type.equals(Type.WARNING) && logLevel>=10)
			log("WARNING: "+ msg);
		else if(type.equals(Type.NORMAL) && logLevel>=10)
			log("NORMAL: "+ msg);
		else if(type.equals(Type.INFO) && logLevel>=20)
			log("INFO: "+ msg);
		else if(type.equals(Type.DEBUG) && logLevel>=30)
			log("DEBUG: "+ msg);
		else if(type.equals(Type.TRACE) && logLevel>=40)
			log("TRACE: "+ msg);
		else if(type.equals(Type.ALL) && logLevel==100)
			log("ALL: "+ msg);
	}
	
	public static void log(String msg) {
		System.out.println(name+": "+msg);
	}

	public static void setName(String sname) {
		name = sname;
	}
}
