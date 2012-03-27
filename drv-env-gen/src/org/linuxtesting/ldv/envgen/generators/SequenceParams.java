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

import java.util.Properties;

public class SequenceParams extends EnvParams {
	enum Length {
		one, n, infinite
	};
	boolean stateful;
	Length length;
	int n;
	
	public SequenceParams(boolean check, boolean stateful, Length length) {
		super(true, check, false, true);
		assert length!=Length.n;
		this.stateful = stateful;
		this.length = length;
		this.n = -1;
	}

	public SequenceParams(boolean check, boolean stateful, int n) {
		super(true, check, false, true);
		this.stateful = stateful;
		this.length = Length.n;
		this.n = n;
	}
	
	public SequenceParams(Properties props, String key) {
		super(props, key);
		String len = props.getProperty(key + ".length");
		assert len!=null && !len.isEmpty() : "parameter length is empty";
		String tlen = len.trim();
		if(tlen.equals("one")) {
			this.length = Length.one;			
		} else if(tlen.equals("infinite")) {
			this.length = Length.infinite;						
		} else if(tlen.equals("n")) {
			this.length = Length.n;
			String n = props.getProperty(key + ".n");
			assert n!=null && !n.isEmpty() : "parameter n is empty";
			this.n = Integer.parseInt(n);
		} else {
			assert false : "unknown length";
		}
		String st = props.getProperty(key + ".stateful", "false");
		if(st.trim().equalsIgnoreCase("true")) {
			this.stateful = true;
		} else {
			this.stateful = false;			
		}
	}

	public boolean isStatefull() {
		return stateful;
	}

	public Length getLength() {
		return length;
	}

	public int getN() {
		return n;
	}

	@Override
	public String getStringId() {
		return "sequence" + "_" + length + (check?"_withcheck":"") + (stateful?"_stateful":"");
	}
	
	
}
