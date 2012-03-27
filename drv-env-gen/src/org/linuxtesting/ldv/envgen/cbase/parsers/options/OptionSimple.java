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
