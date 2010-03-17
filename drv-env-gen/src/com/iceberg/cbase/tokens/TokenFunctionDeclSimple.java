package com.iceberg.cbase.tokens;

import java.util.ArrayList;
import java.util.List;

public class TokenFunctionDeclSimple extends TokenFunctionDecl {

	public static enum SimpleType {
		ST_MODULE_INIT,
		ST_MODULE_EXIT,
		ST_UNKNOWN
	}

	private SimpleType simpleType = SimpleType.ST_UNKNOWN;

	public SimpleType getType() {
		return this.simpleType;
	}

	public TokenFunctionDeclSimple(String name, String retType,
			List<String> replacementParams, int beginIndex, int endIndex,
			String content, SimpleType simpleType) {
		super(name, retType, replacementParams, beginIndex, endIndex, content, null);
		tokens = new ArrayList<Token>();
		tokens.add(this);
		this.simpleType = simpleType;
	}

}
