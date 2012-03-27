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
package org.linuxtesting.ldv.envgen.cbase.parsers.options;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Iterator;
import java.util.Map;


public class ParserOptions {
	private List<Options> optionsByNumber = new ArrayList<Options>();
	private Map<String,Options> optionsByName = new HashMap<String,Options>();
	
	public String getPattern() {
		StringBuffer patternBuffer = new StringBuffer("");
		Iterator<Options> optionsIterator = optionsByNumber.iterator();
		while(optionsIterator.hasNext()) 
			optionsIterator.next().appendPattern(patternBuffer);
		return patternBuffer.toString();
	}
	
	public void sendConfigOption(String optionName, String value) {
		/* вывести мессадж если опции нет */
		Options option = optionsByName.get(optionName);
		option.applyConfigMsg(value);
	}
	
	/* метод для добавления опций */
	public void addOption(Options options) {
		optionsByName.put(options.getName(),options);
		optionsByNumber.add(options);
	}
}
