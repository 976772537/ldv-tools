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
package org.linuxtesting.ldv.envgen;

public class TimeLogger {
	
	private long start = 0;
	private String signature = null;
	
	public TimeLogger(String signature) {
		this.signature = signature;
		TimeLogger.putMsg("ENTER: " + this.signature + '\n');
		this.start = System.currentTimeMillis();
	}
	
	public void putDown() {
		long end = System.currentTimeMillis();
		TimeLogger.putMsg("EXIT : " + this.signature + "\nTIME :" + (end - this.start) +"ms\n");
	}
	
	private static void putMsg(String msg) {
		Logger.info(msg);
	}
}
