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
package org.linuxtesting.ldv.envgen.group;

import org.linuxtesting.ldv.envgen.cbase.tokens.TokenFunctionDecl;

public class VarInfo {
	boolean retvar;
	String replacementParam; 
	int index; 
	TokenFunctionDecl token;
	
	public VarInfo(String replacementParam, int index, TokenFunctionDecl token) {
		this.replacementParam = replacementParam;
		this.index = index;
		this.token = token;
		this.retvar = false;
	}
	
	public VarInfo(String retType, TokenFunctionDecl token) {
		this.replacementParam = retType + " $var";
		this.index = -1;
		this.token = token;
		this.retvar = true;
	}

	public GroupKey getGroupKey() {
		return new GroupKey(replacementParam);
	}
	
	public boolean isStruct() {
		return replacementParam.contains("struct");
	}
	
	public boolean mayBeGrouped() {
		return 
			!replacementParam.equals("...") 
			&& !replacementParam.equals("void")
			&& !replacementParam.contains("const") 
			&& isStruct()
			&& index<2;		
	}

	@Override
	public String toString() {
		return "VarInfo [index=" + index 
				+ ", replacementParam=" + replacementParam 
				+ ", retvar=" + retvar 
				+ "]";
	}

	public boolean isReturnVar() {
		return retvar;
	}
}
