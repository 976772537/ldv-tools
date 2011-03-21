package org.linuxtesting.ldv.envgen.cbase.tokens;

import java.util.List;

public class TokenFunctionDecl extends ContainerToken<TokenFunctionCall> {

	private static int declCounter = 0;

	private String id;
	private String name;
	private String retType;
	private List<String> replacementParams;
	private String test;

	private int beginIndex = 0;
	private int endIndex = 0;
	
	public TokenFunctionDecl(String name, String retType, List<String> replacementParams, int beginIndex, int endIndex, String content, String ldvCommentContent, List<TokenFunctionCall> innerTokens) {
		super(content, ldvCommentContent, innerTokens);
		this.name = name;
		this.retType = retType;
		this.replacementParams = replacementParams;
		this.id = name + "_" + declCounter++;
		this.beginIndex = beginIndex;
		this.endIndex = endIndex;
	}

	public int getBeginIndex() {
		return beginIndex;
	}
	public int getEndIndex() {
		return endIndex;
	}

	public String getId() {
		return id;
	}
	
	public String getName() {
		return name;
	}
	
	public void setComment(String callback) {
		this.ldvCommentContent = callback; 
	}

	public String getRetType() {
		return retType;
	}

	public List<String> getReplacementParams() {
		return replacementParams;
	}

	//public static int getStartVar() {
	//	return startVar;
	//}

	//public static int getIncStartVar() {
	//	return startVar++;
	//}

	public String getTestString() {
		return this.test;
	}
	
	public void setTestString(String string) {
		this.test = string;
	}
	
	@Override
	public String toString() {
		return "TokenFunctionDecl [name=" + name + ", replacementParams="
				+ replacementParams + ", retType=" + retType + ", test=" + test
				+ "]";
	}
}
