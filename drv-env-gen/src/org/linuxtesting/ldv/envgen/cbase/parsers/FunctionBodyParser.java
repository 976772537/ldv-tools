package org.linuxtesting.ldv.envgen.cbase.parsers;

import java.util.List;

import org.linuxtesting.ldv.envgen.cbase.tokens.TokenBodyElement;

public interface FunctionBodyParser {

	List<TokenBodyElement> parse(String buffer);
}