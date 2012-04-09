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

public class TokenPpcDirective extends Token {
	
	public static enum PPCType {
		PPC_LOCAL_INCLUDE,
		PPC_GLOBAL_INCLUDE,
		PPC_IFDEF,
		PPC_ENDIF,
		PPC_ELSE,
		PPC_UNKNOWN,
	}

	private PPCType ppctype;
	private int beginIndex = 0;
	private int endIndex = 0;
		
	public TokenPpcDirective(int beginIndex, int endIndex, String content, String ldvCommentContent, PPCType ppctype) {
		super(content, ldvCommentContent);
		this.ppctype = ppctype;
		this.beginIndex = beginIndex;
		this.endIndex = endIndex;
	}	
	
	public PPCType getPPCType() {
		return this.ppctype;
	}

	public int getBeginIndex() {
		return beginIndex;
	}
	
	public int getEndIndex() {
		return endIndex;
	}
}
