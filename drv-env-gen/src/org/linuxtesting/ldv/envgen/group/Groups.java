package org.linuxtesting.ldv.envgen.group;

import java.util.Map;

import org.linuxtesting.ldv.envgen.Logger;
import org.linuxtesting.ldv.envgen.cbase.tokens.TokenFunctionDecl;

public class Groups {
	
	public static Var getVar(Map<GroupKey, GroupInfo> theGroups,
			String retType, TokenFunctionDecl token) {
		VarInfo info = new VarInfo(token.getRetType(), token);
		return getVar(theGroups, info);
	}

	private static Var getVar(Map<GroupKey, GroupInfo> theGroups, VarInfo info) {
		Var resvar;
		Logger.trace("Create info " + info);
		if(info.mayBeGrouped()) {
			GroupKey k = info.getGroupKey();
			Logger.trace("key=" + k);
			GroupInfo g;
			if(!theGroups.containsKey(k)) {
				Logger.trace("creating group");
				g = new GroupInfo(info);
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

	public static Var getVar(Map<GroupKey, GroupInfo> theGroups,
			String replacementParam, int paramCnt, TokenFunctionDecl token) {
		VarInfo info = new VarInfo(replacementParam, paramCnt, token);
		return getVar(theGroups, info);
	}


}
