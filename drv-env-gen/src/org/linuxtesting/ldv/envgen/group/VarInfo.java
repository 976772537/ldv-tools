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
		return "VarInfo [index=" + index + ", replacementParam="
				+ replacementParam + "]";
	}

	public boolean isReturnVar() {
		return retvar;
	}
}
