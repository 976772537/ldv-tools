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
			List<Token> functionDeclList) {
		super(beginIndex, endIndex, content, functionDeclList);
		this.name = name;
		this.type = type;
	}
}
