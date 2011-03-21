package org.linuxtesting.ldv.envgen.cbase.tokens;

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
			String content, String ldvCommentContent, SimpleType simpleType) {
		super(name, retType, replacementParams, beginIndex, endIndex, content, ldvCommentContent, null);
		tokens = new ArrayList<TokenFunctionCall>();
		//tokens.add(this);
		this.simpleType = simpleType;
	}

}
