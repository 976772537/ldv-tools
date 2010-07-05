package com.iceberg.cbase.tokens;

import java.util.List;

import com.iceberg.cbase.readers.ReaderInterface;

public class Token implements ReaderInterface {

	private int beginIndex = 0;
	private int endIndex = 0;
	private String content=null;
	protected String ldvCommentContent=null;
	protected List<Token> tokens;

	public Token(int beginIndex, int endIndex, String content, String ldvCommentContent, List<Token> tokens) {
		super();
		this.ldvCommentContent = ldvCommentContent;
		this.tokens = tokens;
		this.beginIndex = beginIndex;
		this.endIndex = endIndex;
		this.content = content;
	}
	
	public String getLdvCommentContent() {
		return ldvCommentContent;
	}

	public List<Token> getTokens() {
		return tokens;
	}

	public boolean hasInnerTokens() {
		if(tokens!=null && tokens.size()>0) return true;
		return false;
	}

	public int getBeginIndex() {
		return beginIndex;
	}
	public int getEndIndex() {
		return endIndex;
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
