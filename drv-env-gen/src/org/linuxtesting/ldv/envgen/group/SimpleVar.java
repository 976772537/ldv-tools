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
package org.linuxtesting.ldv.envgen.group;

public class SimpleVar extends Var {
	private VarInfo info;

	public SimpleVar(VarInfo info) {
		super();
		this.info = info;
	}

	@Override
	public String getReplacementParam() {
		return info.replacementParam;
	}

	@Override
	public String getVarName() {
		if(info.isReturnVar()) {
			return getRetName();
		} else {
			return getVarName(info.index);
		}
	}

	private String getVarName(int paramCnt) {
		return "var_"+ info.token.getId() + "_p" + paramCnt;
	}

	private String getRetName() {
		return "res_" + info.token.getId();
	}

	@Override
	public String toString() {
		return "SimpleVar [info=" + info + "]";
	}

	@Override
	public int hashCode() {
		String name = getVarName();
		if(name!=null) {
			return name.hashCode();
		} else {
			return 0;
		}
	}

	@Override
	public boolean equals(Object obj) {
		String name = getVarName();
		if(! (obj instanceof SimpleVar)) {
			return false;
		}
		SimpleVar other = (SimpleVar)obj;
		String name2 = other.getVarName();
		return name==name2 || name!=null && name.equals(name2);
	}
	
}
