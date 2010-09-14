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
