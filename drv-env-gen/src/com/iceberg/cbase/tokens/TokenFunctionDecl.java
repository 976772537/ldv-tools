package com.iceberg.cbase.tokens;

import java.util.List;

public class TokenFunctionDecl extends ContainerToken<Token> {

	private static int startVar = 0;
	private String test;

	private String name;
	private String retType;
	private List<String> replacementParams;

	public TokenFunctionDecl(String name, String retType, List<String> replacementParams, int beginIndex, int endIndex, String content, String ldvCommentContent, List<Token> innerTokens) {
		super(beginIndex, endIndex, content, ldvCommentContent, innerTokens);
		this.name = name;
		this.retType = retType;
		this.replacementParams = replacementParams;
	}

	public String getName() {
		return name;
	}
	
	public void setCallback(String callback) {
		this.ldvCommentContent = callback; 
	}

	public String getRetType() {
		return retType;
	}

	public List<String> getReplacementParams() {
		return replacementParams;
	}

	public static int getStartVar() {
		return startVar;
	}

	public static int getIncStartVar() {
		return startVar++;
	}

	public String getTestString() {
		return this.test;
	}
	
	public void setTestString(String string) {
		this.test = string;
	}
}
