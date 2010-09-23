package org.linuxtesting.ldv.envgen.cbase.parsers.options;

import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

public final class OptionFunctionName extends Options {

	private List<String> patterns;
// Old patterns replaced
//	private static String pattern =    "(}\\s*;?|\\)\\s*;|\\n\\s*)((?!(\\s*(while|sizeof|if|list_for_each_entry|list_for_each_entry_safe|switch|gadget_for_each_ep)\\s*\\())([\\s\\w\\d\\*\\_\\,\\(\\)]*))\\s+\\*?((?!(for)|(if))([_a-zA-Z][_a-z0-9A-Z]*\\s*))\\([\\s\\w\\d\\*\\&\\_\\,\\(\\)]*\\)\\s*\\{";
//	private static String prePattern = "(}\\s*;?|\\)\\s*;|\\n\\s*)((?!(\\s*(while|sizeof|if|list_for_each_entry|list_for_each_entry_safe|switch|gadget_for_each_ep)\\s*\\())([\\s\\w\\d\\*\\_\\,\\(\\)]*))\\s+\\*?(";
	private static String pattern =    "(}\\s*;?|\\)\\s*;|\\n\\s*)((?!(\\s*(while|sizeof|if|list_for_each_entry|list_for_each_entry_safe|switch|gadget_for_each_ep)\\s*\\())([\\s\\w\\d\\*\\_\\,\\(\\)]*))\\s+\\*?((?!(for)|(if))([_a-zA-Z][_a-z0-9A-Z]*\\s*))\\([\\s\\w\\d\\*\\&\\_\\,]*\\)\\s*\\{";
	private static String prePattern = "(}\\s*;?|\\)\\s*;|\\n\\s*)((?!(\\s*(while|sizeof|if|list_for_each_entry|list_for_each_entry_safe|switch|gadget_for_each_ep)\\s*\\())([\\s\\w\\d\\*\\_\\,\\(\\)]*))\\s+\\*?(";
	private static String afterPattern = ")\\s*\\([\\s\\w\\d\\*\\&\\_\\,]*\\)\\s*\\{";

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
