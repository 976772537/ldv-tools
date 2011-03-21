package org.linuxtesting.ldv.envgen.cbase.tokens;

import java.util.List;

import org.linuxtesting.ldv.envgen.cbase.readers.ReaderInterface;


public class Token implements ReaderInterface {

	private String content=null;
	protected String ldvCommentContent=null;

	public Token(String content, String ldvCommentContent) {
		super();
		this.ldvCommentContent = ldvCommentContent;
		this.content = content;
	}
	
	public String getLdvCommentContent() {
		return ldvCommentContent;
	}

	public String readAll() {
		return getContent();
	}

	public String getContent() {
		return content;
	}

	public static void deleteCopiesEqualsByContent(List<Token> tokens) {
		for(int i=0; i<tokens.size(); i++) {
			for(int j=0; j<tokens.size(); j++) {
				if(tokens.get(i).getContent().equals(tokens.get(j).getContent())) {
					tokens.remove(j);
					j--;
				}
			}
		}
	}
}
