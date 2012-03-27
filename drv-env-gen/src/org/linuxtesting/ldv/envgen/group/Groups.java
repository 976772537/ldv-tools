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

import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;

import org.linuxtesting.ldv.envgen.Logger;
import org.linuxtesting.ldv.envgen.cbase.tokens.TokenFunctionDecl;

public class Groups {

	private Map<GroupKey, GroupInfo> theGroups = new HashMap<GroupKey, GroupInfo>();
	private HashSet<Var> declared = new HashSet<Var>();
	private HashSet<Var> initialized = new HashSet<Var>();
	boolean enabled = true;
	
	public Var getVar(String retType, TokenFunctionDecl token) {
		VarInfo info = new VarInfo(token.getRetType(), token);
		return getVar(info);
	}

	public boolean isDeclared(Var v) {
		return declared.contains(v);
	}
	
	public boolean isInitialized(Var v) {
		return initialized.contains(v);
	}
	
	public void addDeclared(Var v) {
		declared.add(v);
	}
	
	public void addInitialized(Var v) {
		initialized.add(v);
	}
	
	private Var getVar(VarInfo info) {
		Var resvar;
		Logger.trace("Create info " + info);
		if(enabled && info.mayBeGrouped()) {
			GroupKey k = info.getGroupKey();
			Logger.trace("key=" + k);
			GroupInfo g;
			Logger.trace("theGroups=" + theGroups);
			if(!theGroups.containsKey(k)) {
				Logger.trace("creating group");
				g = new GroupInfo(info);
				theGroups.put(k, g);
			} else {
				Logger.trace("existing group");
				g = theGroups.get(k);				
			}
			Logger.trace("group=" + g);
			resvar = new GroupVar(info, g);
		} else {
			Logger.trace("simple var");
			resvar = new SimpleVar(info);
		}
		Logger.trace("var=" + resvar);
		return resvar;
	}

	public Var getVar(String replacementParam, int paramCnt, TokenFunctionDecl token) {
		VarInfo info = new VarInfo(replacementParam, paramCnt, token);
		return getVar(info);
	}

	public void setEnabled(boolean grouped) {
		Logger.trace("enabled=" + grouped);
		this.enabled = grouped;
	}
}
