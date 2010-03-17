package com.iceberg.cbase.parsers.options;

public class OptionSimple extends Options {

	/* если планирется именять или добавлять module_init, module_exit - части
	 * то их также нужно будет изменить и в парсере */
	private static String patternSimple = "\\s+(subsys_initcall|module_init|module_exit)\\s*\\(\\s*[_a-zA-Z][_a-zA-Z0-9]*\\s*\\)";

	public OptionSimple() {
		super("simple");
	}

	@Override
	public void appendPattern(StringBuffer buffer) {
		buffer.append(patternSimple);
	}

	@Override
	public void applyConfigMsg(String value) {
		/* можно сделать поиск только exit'ов или только init'ов */
	}

}
