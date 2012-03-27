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

public class PlainParams extends EnvParams {
	
	public PlainParams(boolean check) {		
		super(true, check, false, true);
	}
	
	protected PlainParams(boolean sorted, boolean check, boolean init, boolean grouped) {		
		super(sorted, check, init, grouped);
	}
	
	public PlainParams(Properties props, String key) {
		super(props, key);
	}

	@Override
	public String getStringId() {
		return "plain" + (sorted?"_sorted":"") + (check?"_withcheck":"");
	}
}
