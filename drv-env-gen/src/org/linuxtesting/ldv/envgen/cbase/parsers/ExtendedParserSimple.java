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
package org.linuxtesting.ldv.envgen.cbase.parsers;

import java.util.List;

import org.linuxtesting.ldv.envgen.cbase.parsers.ExtendedParserStruct.NameAndType;
import org.linuxtesting.ldv.envgen.cbase.parsers.options.OptionSimple;
import org.linuxtesting.ldv.envgen.cbase.readers.ReaderInterface;
import org.linuxtesting.ldv.envgen.cbase.tokens.TokenFunctionDecl;
import org.linuxtesting.ldv.envgen.cbase.tokens.TokenFunctionDeclSimple;


/**
 * парсер для поиска init и exit макросов и токенов функций
 * в соответствующих макросах
 *
 * @author Alexander Strakh
 *
 */
public class ExtendedParserSimple extends ExtendedParser<TokenFunctionDeclSimple> {

	public ExtendedParserSimple(ReaderInterface reader) {
		super(reader);
		addOption(new OptionSimple());
	}

	@Override
	protected TokenFunctionDeclSimple parseContent(String content, int start, int end) {
		String tokenClearContent = content.trim();
		NameAndType nameAndType = parseNameAndType(tokenClearContent);
		/* создадим парсер функций */
		ExtendedParserFunction innerParserFunctions = new ExtendedParserFunction(getReader());
		/* и добавим в него поиск только по указанным именам функций */
		innerParserFunctions.addConfigOption("name", nameAndType.getName());
		/* и запустим парсер */
		List<TokenFunctionDecl> functions = innerParserFunctions.parse();
		if(functions == null || functions.size() == 0)
			return null;
		TokenFunctionDecl oneToken = functions.get(0);
		TokenFunctionDeclSimple token = null;
		if(nameAndType.getType().equals("module_init")) {
			token = new TokenFunctionDeclSimple(nameAndType.getName(),
					oneToken.getRetType(), oneToken.getReplacementParams(),
					oneToken.getBeginIndex() ,
					oneToken.getEndIndex(),
					oneToken.getContent(),
					null,
					TokenFunctionDeclSimple.SimpleType.ST_MODULE_INIT);
		} else
			if(nameAndType.getType().equals("module_exit")) {
				token = new TokenFunctionDeclSimple(nameAndType.getName(),
						oneToken.getRetType(), oneToken.getReplacementParams(),
						oneToken.getBeginIndex() ,
						oneToken.getEndIndex(),
						oneToken.getContent(), 
						null, 
						TokenFunctionDeclSimple.SimpleType.ST_MODULE_EXIT);
		}
		return token;
	}

	private NameAndType parseNameAndType(String tokenClearContent) {
		NameAndType nameAndType;
		int square_index = tokenClearContent.indexOf("(");
		if(tokenClearContent.contains("module_init") && tokenClearContent.indexOf("module_init")<square_index) {
			nameAndType = new NameAndType(
					tokenClearContent.replaceFirst("module_init\\s*\\(", "").replace(")", "").trim(),
					"module_init");
		} else
		if(tokenClearContent.contains("module_exit") && tokenClearContent.indexOf("module_exit")<square_index) {
			nameAndType = new NameAndType(
					tokenClearContent.replaceFirst("module_exit\\s*\\(", "").replace(")", "").trim(),
					"module_exit");
		} else
		if(tokenClearContent.contains("subsys_initcall") && tokenClearContent.indexOf("subsys_initcall")<square_index) {
			nameAndType = new NameAndType(
					tokenClearContent.replaceFirst("subsys_initcall\\s*\\(", "").replace(")", "").trim(),
					"module_init");
		} else {
			assert false; 
			nameAndType = null;
		}
		return nameAndType;
	}

}
