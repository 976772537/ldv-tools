/*
 * Copyright (C) 2010-2012
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

import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.linuxtesting.ldv.envgen.Logger;
import org.linuxtesting.ldv.envgen.cbase.tokens.TokenBodyElement;
import org.linuxtesting.ldv.envgen.cbase.tokens.TokenFunctionCall;
import org.linuxtesting.ldv.envgen.cbase.tokens.TokenFunctionDecl;

public class FunctionCallParser implements FunctionBodyParser {
	/* паттерн нужен, чтобы следующей за ним функции распарсить по нему
	 * вызовы функций */
	private final static Pattern fcallsPatterns = Pattern.compile(
			"[\\w\\$]+\\s*\\("
			+ "[\\[\\]\\d\\:\\*\\&\\w\\,\\.\\?\\%\\$\\^\\s\\=\\_\\\"\\\\\\#\\-(\\s*\\-\\s*>\\s*)\\(\\)]*"
			+ "\\)\\s*");
	//private static Pattern fcallsRulePatterns = Pattern.compile("[_a-zA-Z$][_a-zA-Z0-9$]*");

	private int parseExceptionCounter = 0;

	public int getParseExceptionCounter() {
		return parseExceptionCounter;
	}

	/* на вход подается - тело функции, вместе с заголовком "abracadabre() { if.. print.. }" */
	@Override
	public List<TokenBodyElement> parse(String buffer) {
		List<TokenBodyElement> tokens = new ArrayList<TokenBodyElement>();
		/* подготавливаем и компилим паттерны */
		Matcher matcher = fcallsPatterns.matcher(buffer.substring(buffer.indexOf('{')));
		/* матчим контент */
		/* возможно, перед тем как матчитить придется убирать
		 * блоки вида "...", иначе матчер будет брать вызовы функций и из
		 * printk- комментариев в том числе */
		while(matcher.find()) {
			try {
				String callsString = matcher.group();
				TokenFunctionCall token = TokenFunctionCall.create(matcher.start(), matcher.end(), callsString);
				if(token!=null) {
					/* смотрим, есть ли ли уже такой токен (равный по полю контент) */
					if(!TokenBodyElement.isDuplicateByName(token, tokens)) {
						Logger.debug("new token " + token);
						tokens.add(token);							
					} else {
						Logger.debug("token already added, name=" + token.getName());
					}
				}				
			} catch (Exception e) {
				Logger.debug(" parse exception - "+ ++parseExceptionCounter);
			}
		}
		return tokens;
	}

	public static List<TokenFunctionCall> getFunctionCalls(TokenFunctionDecl tfd) {
		List<TokenBodyElement> tokens = tfd.getTokens();
		List<TokenFunctionCall> res = new ArrayList<TokenFunctionCall>(tokens.size());
		for(TokenBodyElement t : tokens) {
			if(t instanceof TokenFunctionCall) {
				res.add((TokenFunctionCall)t);
			}
		}
		return res;
	}	
}
