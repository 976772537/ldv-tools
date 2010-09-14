package org.linuxtesting.ldv.envgen.cbase.parsers.options;

import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.regex.Pattern;

public class OptionStructType extends Options {

	public OptionStructType() {
		super("type");
	}

	private List<String> patterns = null;
	//private static Pattern pattern = Pattern.compile("(\\s\\\\*\\s*static\\s+(const\\s+)?struct[\\*\\s]+)[a-zA-Z_][a-zA-Z0-9_]*[\\\\*\\s]+[a-zA-Z_][a-zA-Z0-9_]*[\\\\*\\s]+[=]{1,1}[\\\\*\\s]\\{[\\s\\*]*");
	//private static String prePattern = "(\\s\\\\*\\s*static\\s+(const\\s+)?struct[\\*\\s]+)(";
	//private static String afterPattern = ")[\\\\*\\s]+[a-zA-Z_][a-zA-Z0-9_]*[\\\\*\\s]+[=]{1,1}[\\\\*\\s]\\{[\\s\\*]*";

	/* TODO: паттерны структур
	 * НОВЫЕ ПАТТЕРНЫ: теперь матчит нестатические структуры
	 *  - проявляется на linux-2.6.31    /drivers/i2c/i2c_core.c структура i2c_bus_type
	 *  - оттестить и отбросить новый заматченный мусор
	 */
	 private static Pattern pattern = Pattern.compile("(\\s\\\\*\\s*(static\\s*)?+(const\\s+)?struct[\\*\\s]+)[a-zA-Z_][a-zA-Z0-9_]*[\\\\*\\s]+[a-zA-Z_][a-zA-Z0-9_]*[\\\\*\\s]+[=]{1,1}[\\\\*\\s]\\{[\\s\\*]*");
	 private static String prePattern = "(\\s\\\\*\\s*(static\\s*)?+(const\\s+)?struct[\\*\\s]+)(";
	 private static String afterPattern = ")[\\\\*\\s]+[a-zA-Z_][a-zA-Z0-9_]*[\\\\*\\s]+[=]{1,1}[\\\\*\\s]\\{[\\s\\*]*";
	 /*
	 */

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
