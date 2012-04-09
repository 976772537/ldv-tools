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

import java.util.ArrayList;
import java.util.List;

public class TokenFunctionDeclSimple extends TokenFunctionDecl {

	public static enum SimpleType {
		ST_MODULE_INIT,
		ST_MODULE_EXIT,
		ST_UNKNOWN
	}

	private SimpleType simpleType = SimpleType.ST_UNKNOWN;

	public SimpleType getType() {
		return this.simpleType;
	}

	public TokenFunctionDeclSimple(String name, String retType, 
			List<String> replacementParams, int beginIndex, int endIndex,
			String content, String ldvCommentContent, SimpleType simpleType) {
		super(name, retType, replacementParams, beginIndex, endIndex, content, ldvCommentContent, null);
		tokens = new ArrayList<TokenBodyElement>();
		//tokens.add(this);
		this.simpleType = simpleType;
	}

}
