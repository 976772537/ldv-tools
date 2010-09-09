package com.iceberg.cbase.parsers;

import java.util.List;

import com.iceberg.cbase.tokens.Token;

public interface ParserInterface<T extends Token> {
	public List<T> parse();
}
