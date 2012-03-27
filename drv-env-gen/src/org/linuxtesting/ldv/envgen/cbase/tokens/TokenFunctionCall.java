/*
 * Copyright 2010-2012
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
package org.linuxtesting.ldv.envgen.cbase.tokens;

import java.util.Arrays;
import java.util.List;

import org.linuxtesting.ldv.envgen.Logger;
import org.linuxtesting.ldv.envgen.cbase.parsers.ExtendedParserFunction;

public class TokenFunctionCall extends TokenBodyElement {

	List<String> params;
	
	public TokenFunctionCall(String name, List<String> params, int beginIndex, int endIndex, String content,
			String ldvCommentContent) {
		super(name, content, ldvCommentContent);
		this.params = params;
	}

	public List<String> getParams() {
		return params;
	}
	
	public static TokenFunctionCall create(int start, int end, String callsString) {
		Logger.info("parsing call string " + callsString);			
		
		/* оставим только имя */
		String name = callsString.substring(0,callsString.indexOf('(')).trim();
		/* проверим имя - это действительно имя функции, а не ключевое слово */
		if(!isKeyword(name)) {
			/* здесь создаем токен и отправляем в списиок */
			Logger.info("adding call token " + name);			
			
			/*if (buffer.contains("m_extract_one_cell") && token.getContent().contains("atomic_inc")) {
				System.out.printf("m_extract_one_cell");
			}*/
			List<String> params = ExtendedParserFunction.parseParams(callsString, name);
			return new TokenFunctionCall(name, params, start, end, callsString, "todo comment");
		} else {
			Logger.debug("Function name is a keyword " + name); 
			return null;
		}
	}

	private static final List<String> keywordsList = 
		Arrays.asList("while","do","if","else","for","return");	
	
	private static boolean isKeyword(String name) {
		for(int i=0; i<keywordsList.size(); i++)
			if(keywordsList.get(i).equals(name))
				return true;
		return false;
	}

	@Override
	public String toString() {
		return "TokenFunctionCall [name=" + name + ", params=" + params + "]";
	}

}
