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
