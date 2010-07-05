package com.iceberg.cbase.tokens;

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
	
	public TokenPpcDirective(int beginIndex, int endIndex, String content, String ldvCommentContent, PPCType ppctype) {
		super(beginIndex, endIndex, content, ldvCommentContent, null);
		this.ppctype = ppctype;
	}	
	
	public PPCType getPPCType() {
		return this.ppctype;
	}
}
