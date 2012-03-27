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
package org.linuxtesting.ldv.envgen.cbase.parsers;

import org.linuxtesting.ldv.envgen.cbase.tokens.Token;

public class CallbackItem<T extends Token> extends Item<T> {
 
	public static final String LDV_IN_INTERRUPT = "LDV_IN_INTERRUPT";
	public static final String LDV_IN_INTERRUPT_OUT = "1";
	public static final String LDV_IN_INTERRUPT_IN = "2";
	
	public static String getInterruptVarDecl() {
		return "int " + LDV_IN_INTERRUPT;
	}
	
	public static String getInterruptInit() {
		return LDV_IN_INTERRUPT + "=" + LDV_IN_INTERRUPT_OUT;
	}
	
	public CallbackItem(T data) {
		super(data);
	}

	@Override
	public String getDeclarationStr(String id) {
		return "";
	}

	@Override
	public String getPreconditionStrBegin(String id) {
		return LDV_IN_INTERRUPT + "=" + LDV_IN_INTERRUPT_IN + ";";
	}

	@Override
	public String getPreconditionStrEnd(String id) {
		return "";
	}

	@Override
	public String getUpdateStr(String id) {
		return LDV_IN_INTERRUPT + "=" + LDV_IN_INTERRUPT_OUT + ";";
	}

	@Override
	public String getCompletionCheckStr(String id) {
		return "";
	}
}
