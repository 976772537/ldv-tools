package org.linuxtesting.ldv.envgen.cbase.parsers;

import org.linuxtesting.ldv.envgen.cbase.tokens.Token;

public class TimerItem<T extends Token> extends Item<T> {

	public TimerItem(T data) {
		super(data);
	}

	@Override
	public String getDeclarationStr(String id) {
		return "";
	}

	@Override
	public String getPreconditionStrBegin(String id) {
		return "";
	}

	@Override
	public String getPreconditionStrEnd(String id) {
		return "";
	}

	@Override
	public String getUpdateStr(String id) {
		return "";
	}

	@Override
	public String getCompletionCheckStr(String id) {
		return "";
	}
}
