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
import java.util.Iterator;
import java.util.List;

public final class OptionFunctionName extends Options {

	private List<String> patterns;
// Old patterns replaced
//	private static String pattern =    "(}\\s*;?|\\)\\s*;|\\n\\s*)((?!(\\s*(while|sizeof|if|list_for_each_entry|list_for_each_entry_safe|switch|gadget_for_each_ep)\\s*\\())([\\s\\w\\d\\*\\_\\,\\(\\)]*))\\s+\\*?((?!(for)|(if))([_a-zA-Z][_a-z0-9A-Z]*\\s*))\\([\\s\\w\\d\\*\\&\\_\\,\\(\\)]*\\)\\s*\\{";
//	private static String prePattern = "(}\\s*;?|\\)\\s*;|\\n\\s*)((?!(\\s*(while|sizeof|if|list_for_each_entry|list_for_each_entry_safe|switch|gadget_for_each_ep)\\s*\\())([\\s\\w\\d\\*\\_\\,\\(\\)]*))\\s+\\*?(";
	private static String pattern =    	"(}\\s*;?|\\)\\s*;|\\n\\s*)((?!(\\s*(while|sizeof|if|list_for_each_entry|list_for_each_entry_safe|switch|gadget_for_each_ep)\\s*\\())([\\s\\w\\d\\*\\_\\,\\(\\)]*))\\s+\\*?(" +
										"(?!(\\bfor\\b)|(\\bif\\b))([_a-zA-Z][_a-z0-9A-Z]*\\s*)" +
										//"iforce_usb_probe" +
										")\\" + "s*\\" +
										"([\\s\\w\\d\\*\\&\\_\\,]*\\)\\s*\\{";
	private static String prePattern = 	"(}\\s*;?|\\)\\s*;|\\n\\s*)((?!(\\s*(while|sizeof|if|list_for_each_entry|list_for_each_entry_safe|switch|gadget_for_each_ep)\\s*\\())([\\s\\w\\d\\*\\_\\,\\(\\)]*))\\s+\\*?(";
	private static String afterPattern =")\\s*\\" +
										"([\\s\\w\\d\\*\\&\\_\\,]*\\)\\s*\\{";

	public OptionFunctionName() {
		super("name");
	}

	@Override
	public void appendPattern(StringBuffer buffer) {
		if(patterns == null) {
			buffer.append(pattern);
			return;
		}
		/* собираем паттерн */
		buffer.append(prePattern);
		Iterator<String> patternIterator = patterns.iterator();
		while (patternIterator.hasNext()) {
			buffer.append(patternIterator.next());
			if (patternIterator.hasNext())
				buffer.append("|");
		}
		buffer.append(afterPattern);
	}

	@Override
	public void applyConfigMsg(String value) {
		if(patterns == null) patterns = new ArrayList<String>();
		this.patterns.add(value);
	}
}
