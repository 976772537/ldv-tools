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

public class ContainerToken<T extends Token> extends Token {

	protected List<T> tokens;
	
	public List<T> getTokens() {
		return tokens;
	}

	public boolean hasInnerTokens() {
		if(tokens!=null && tokens.size()>0) return true;
		return false;
	}

	public ContainerToken(String content,
			String ldvCommentContent, List<T> tokens) {
		super(content, ldvCommentContent);
		this.tokens = tokens;
	}

}
