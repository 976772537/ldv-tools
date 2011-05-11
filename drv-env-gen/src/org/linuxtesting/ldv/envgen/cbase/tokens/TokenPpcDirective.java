package org.linuxtesting.ldv.envgen.cbase.tokens;

public class TokenPpcDirective extends Token {
	
	public static enum PPCType {
		PPC_LOCAL_INCLUDE,
		PPC_GLOBAL_INCLUDE,
		PPC_IFDEF,
		PPC_ENDIF,
		PPC_ELSE,
		PPC_UNKNOWN,
	}

	private PPCType ppctype;
	private int beginIndex = 0;
	private int endIndex = 0;
		
	public TokenPpcDirective(int beginIndex, int endIndex, String content, String ldvCommentContent, PPCType ppctype) {
		super(content, ldvCommentContent);
		this.ppctype = ppctype;
		this.beginIndex = beginIndex;
		this.endIndex = endIndex;
	}	
	
	public PPCType getPPCType() {
		return this.ppctype;
	}

	public int getBeginIndex() {
		return beginIndex;
	}
	
	public int getEndIndex() {
		return endIndex;
	}
}
