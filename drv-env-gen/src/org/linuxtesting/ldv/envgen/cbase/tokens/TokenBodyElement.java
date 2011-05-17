package org.linuxtesting.ldv.envgen.cbase.tokens;

import java.util.List;

public class TokenBodyElement extends Token {
	protected String name;
	
	public String getName() {
		return name;
	}

	public TokenBodyElement(String name, String content, String ldvCommentContent) {
		super(content, ldvCommentContent);
		this.name = name;
	}

	public static boolean isDuplicateByName(TokenBodyElement token, List<TokenBodyElement> tokens) {
		for(int i=0; i<tokens.size(); i++) {
			if(tokens.get(i).getName().equals(token.getName())) {
				return true;
			}
		}
		return false;
	}

	@Override
	public String toString() {
		return "name=" + name;
	}
}
