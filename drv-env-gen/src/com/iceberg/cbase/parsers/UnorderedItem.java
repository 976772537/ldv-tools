package com.iceberg.cbase.parsers;

import com.iceberg.cbase.tokens.Token;

public class UnorderedItem<T extends Token> extends Item<T> {

	public UnorderedItem(T data) {
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

}
