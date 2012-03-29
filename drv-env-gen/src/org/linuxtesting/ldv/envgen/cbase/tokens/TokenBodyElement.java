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
package org.linuxtesting.ldv.envgen.cbase.tokens;

import java.util.List;

public class TokenBodyElement extends Token {
	protected String name;
	
	public String getName() {
		return name;
	}

	public TokenBodyElement(String name, String content, String ldvCommentContent) {
		super(content, ldvCommentContent);
		this.name = name;
	}

	public static boolean isDuplicateByName(TokenBodyElement token, List<TokenBodyElement> tokens) {
		for(int i=0; i<tokens.size(); i++) {
			if(tokens.get(i).getName().equals(token.getName())) {
				return true;
			}
		}
		return false;
	}

	@Override
	public String toString() {
		return "name=" + name;
	}
}
