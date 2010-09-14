package org.linuxtesting.ldv.envgen.cbase.parsers;

import org.linuxtesting.ldv.envgen.cbase.tokens.Token;

public abstract class Item<T extends Token> {
	T data;

	public Item(T data) {
		this.data = data;
	}

	public T getData() {
		return data;
	}

	public void setData(T data) {
		this.data = data;
	}

	public abstract String getPreconditionStrBegin(String id);
	public abstract String getPreconditionStrEnd(String id);
	public abstract String getUpdateStr(String id);
	public abstract String getDeclarationStr(String id);
}
