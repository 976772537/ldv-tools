package org.linuxtesting.ldv.envgen.cbase.parsers;

import java.util.List;

import org.linuxtesting.ldv.envgen.cbase.tokens.Token;


public interface ParserInterface<T extends Token> {
	public List<T> parse();
}
