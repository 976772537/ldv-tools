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

import java.util.List;

import org.linuxtesting.ldv.envgen.cbase.readers.ReaderInterface;


public class Token implements ReaderInterface {

	private String content=null;
	protected String ldvCommentContent=null;

	public Token(String content, String ldvCommentContent) {
		super();
		this.ldvCommentContent = ldvCommentContent;
		this.content = content;
	}
	
	public String getLdvCommentContent() {
		return ldvCommentContent;
	}

	public String readAll() {
		return getContent();
	}

	public String getContent() {
		return content;
	}

	public static void deleteCopiesEqualsByContent(List<Token> tokens) {
		for(int i=0; i<tokens.size(); i++) {
			for(int j=0; j<tokens.size(); j++) {
				if(tokens.get(i).getContent().equals(tokens.get(j).getContent())) {
					tokens.remove(j);
					j--;
				}
			}
		}
	}
}
