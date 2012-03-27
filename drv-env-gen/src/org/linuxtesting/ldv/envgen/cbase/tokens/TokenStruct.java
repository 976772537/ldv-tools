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

import java.util.ArrayList;
import java.util.List;

import org.linuxtesting.ldv.envgen.cbase.parsers.PatternSorter;
import org.linuxtesting.ldv.envgen.cbase.parsers.ExtendedParserStruct.NameAndType;

public class TokenStruct extends TokenFuncCollection {
	private String name;
	private String type;
	
	@Override
	public String getName() {
		return name;
	}

	public String getType() {
		return type;
	}
	
	public TokenStruct(String name, String type, int beginIndex, int endIndex, String content, 
			String ldvCommentContent, List<TokenFunctionDecl> functionDeclList) {
		super(content, ldvCommentContent, functionDeclList);
		this.name = name;
		this.type = type;
	}
		
	@Override
	public String getId() {
		return name + "_" + type;
	}

	@Override
	public String getDesc() {
		return "STRUCT: struct type: " + type + ", struct name: " + name;
	}
	
	public void sortFunctions(PatternSorter patternSorter, List<NameAndType> fnames) {
		assert sorted==false : "please do not sort twice";
		
		List<NameAndType> fnamesPattern = new ArrayList<NameAndType>(fnames);
		List<TokenFunctionDecl> decls = new ArrayList<TokenFunctionDecl>(tokens);
		
		sortedItems = patternSorter.sortByPattern(type, fnamesPattern, decls);
		
		//support old style of using sorted results through tokens field
		//List<TokenFunctionDecl> newTokens = new ArrayList<TokenFunctionDecl>(tokens.size());
		//for(Item<TokenFunctionDecl> t : sortedItems) {
		//	newTokens.add(t.getData());
		//}
		//tokens = newTokens;		
		sorted = true;
	}
	
	public void setComments(List<NameAndType> fnamesPattern) {
		for(TokenFunctionDecl tfd: tokens) {
			// ищем для него соответствующий тип
			for(NameAndType nt : fnamesPattern) {
				if(nt.getName().equals(tfd.getName())) {
					tfd.setComment(nt.getType());
					break;
				}
			}
		}
	}
}
