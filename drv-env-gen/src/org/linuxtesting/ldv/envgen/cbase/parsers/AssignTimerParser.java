package org.linuxtesting.ldv.envgen.cbase.parsers;

import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.linuxtesting.ldv.envgen.Logger;
import org.linuxtesting.ldv.envgen.cbase.tokens.TokenAssignTimer;
import org.linuxtesting.ldv.envgen.cbase.tokens.TokenBodyElement;
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

}
