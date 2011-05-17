package org.linuxtesting.ldv.envgen.cbase.tokens;

import java.util.List;

public class ContainerToken<T extends Token> extends Token {

	protected List<T> tokens;
	
	public List<T> getTokens() {
		return tokens;
	}

	public boolean hasInnerTokens() {
		if(tokens!=null && tokens.size()>0) return true;
		return false;
	}

	public ContainerToken(String content,
			String ldvCommentContent, List<T> tokens) {
		super(content, ldvCommentContent);
		this.tokens = tokens;
	}

}
