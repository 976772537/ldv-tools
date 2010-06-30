package com.iceberg.cbase.tokens;

import java.util.List;

public class TokenStruct extends Token {
	/* список функций, которые содержаться в структурах */
	
	
	private String name;
	private String type;
	
	public String getName() {
		return name;
	}

	public String getType() {
		return type;
	}
	
	public TokenStruct(String name, String type, int beginIndex, int endIndex, String content, 
			String ldvCommentContent, List<Token> functionDeclList) {
		super(beginIndex, endIndex, content, ldvCommentContent, functionDeclList);
		this.name = name;
		this.type = type;
	}
}
