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
import java.util.HashSet;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.linuxtesting.ldv.envgen.Logger;
import org.linuxtesting.ldv.envgen.cbase.tokens.TimerCollectionToken;
import org.linuxtesting.ldv.envgen.cbase.tokens.TokenAssignTimer;
import org.linuxtesting.ldv.envgen.cbase.tokens.TokenBodyElement;
import org.linuxtesting.ldv.envgen.cbase.tokens.TokenFuncCollection;
import org.linuxtesting.ldv.envgen.cbase.tokens.TokenFunctionDecl;

public class AssignTimerParser implements FunctionBodyParser {

	private final static Pattern timersPatterns = Pattern.compile(
            "."  + "\\s*"
            + "function"  + "\\s*" 
			+ "="  + "\\s*"
			+ "[\\w\\$]+" + "\\s*" 
            + ";"  + "\\s*");

	@Override
	public List<TokenBodyElement> parse(String buffer) {
		Logger.trace("Parse timers");
		List<TokenBodyElement> tokens = new ArrayList<TokenBodyElement>();
		/* подготавливаем и компилим паттерны */
		Matcher matcher = timersPatterns.matcher(buffer.substring(buffer.indexOf('{')));
		/* матчим контент */
		/* возможно, перед тем как матчитить придется убирать
		 * блоки вида "...", иначе матчер будет брать вызовы функций и из
		 * printk- комментариев в том числе */
		while(matcher.find()) {
			try {
				String content = matcher.group();
				String name = getName(content);
				assert name!=null;
				Logger.debug("The name is " + name);
				if(!name.isEmpty()) {
					TokenAssignTimer timer = new TokenAssignTimer(name, content, "todo comment");
					/* смотрим, есть ли ли уже такой токен (равный по полю контент) */
					if(!TokenBodyElement.isDuplicateByName(timer, tokens)) {
						Logger.debug("new token " + timer);
						tokens.add(timer);							
					} else {
						Logger.debug("token already added, name=" + timer.getName());
					}
				}
			} catch (Exception e) {
				assert false;
			}
		}
		return tokens;
	}

	private String getName(String content) {
		int b = content.indexOf('=');
		assert b!=-1;
		int e = content.indexOf(';', b+1);
		assert e!=-1;
		return content.substring(b+1, e).trim();
	}

	public static List<TokenAssignTimer> getTimers(TokenFunctionDecl tfd) {
		List<TokenBodyElement> tokens = tfd.getTokens();
		List<TokenAssignTimer> res = new ArrayList<TokenAssignTimer>(tokens.size());
		for(TokenBodyElement t : tokens) {
			if(t instanceof TokenAssignTimer) {
				res.add((TokenAssignTimer)t);
			}
		}
		return res;
	}	

	public static TokenFuncCollection createTimers(
			Map<String, TokenFunctionDecl> parsedFunctions) {
		Logger.debug("Create timers");
		List<TokenFunctionDecl> tokens = new LinkedList<TokenFunctionDecl>();
		Set<String> set = new HashSet<String>();
		for(Map.Entry<String, TokenFunctionDecl> e : parsedFunctions.entrySet()) {
			TokenFunctionDecl tfd = e.getValue();
			assert tfd.getTokens()!=null;
			for(TokenAssignTimer assignTimer : AssignTimerParser.getTimers(tfd)) {
				Logger.debug("Process timer=" + assignTimer);
				String name = assignTimer.getName();
				assert name!=null;
				TokenFunctionDecl timer = parsedFunctions.get(name);
				if(timer!=null) {
					if(set.contains(timer.getName())) {
						Logger.debug("Duplicate timer=" + name);
					} else {
						Logger.debug("timer found " + timer.getName());
						Logger.debug("check params");
						if(timer.getRetType()!=null && timer.getRetType().contains("void")) {
							Logger.debug("return type matched");
							List<String> pr = timer.getReplacementParams();
							if(pr.size()==1) {
								String first = pr.get(0);
								Logger.debug("params size matched first=" + first);
								if(Pattern.matches(
										"\\s*" + "unsigned"
										+ "\\s*" + "long" 
										+ "\\s*" + "\\$\\w*" + "\\s*", first)) {
									Logger.debug("types matched");
									Logger.debug("add timer " + timer.getName());
									tokens.add(timer);
									set.add(timer.getName());
								}
							}
						}
					}
				} else {
					Logger.debug("timer not found " + name);
				}
			}
		}
		return new TimerCollectionToken("timer", "timer calls", tokens);
	}	
}
