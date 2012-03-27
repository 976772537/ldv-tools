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

import java.util.Arrays;
import java.util.LinkedList;
import java.util.List;

public class DegResult {

	boolean result;
	List<String> mains = new LinkedList<String>();
	
	public DegResult(boolean b) {
		this.result = false;
	}

	public DegResult(List<String> mains) {
		this.result = true;
		this.mains.addAll(mains);
	}
	
	public DegResult(String... ids) {
		this.result = true;
		mains.addAll(Arrays.asList(ids));
	}

	public boolean isSuccess() {
		return result;
	}

	public List<String> getMains() {
		return mains;
	}

}
