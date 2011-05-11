package org.linuxtesting.ldv.envgen.cbase.tokens;

public class TokenAssignTimer extends TokenBodyElement {

	public TokenAssignTimer(String name, String content, String ldvCommentContent) {
		super(name, content, ldvCommentContent);
	}

	@Override
	public String toString() {
		return "TokenAssignTimer [name=" + name + "]";
	}
}
