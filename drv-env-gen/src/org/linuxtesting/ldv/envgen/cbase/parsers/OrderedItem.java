package org.linuxtesting.ldv.envgen.cbase.parsers;

import org.linuxtesting.ldv.envgen.cbase.tokens.Token;

public class OrderedItem<T extends Token> extends Item<T> {
	final String groupcnt = "ldv_s_";
	boolean isLast;
	int myNumber;
	
	//Im not last: if(groupcnt==MYNUMBER) do; after groupcnt++
	//Im last: if(groupcnt==MYNUMBER) do; after groupcnt=0;
	
	public OrderedItem(T data, boolean isLast, int myNumber) {
		super(data);
		this.isLast = isLast;
		this.myNumber = myNumber;
	}

	@Override
	public String getPreconditionStrBegin(String id) {
		return "if(" + groupcnt + id + "==" + myNumber + ") {";
	}
	
	@Override
	public String getPreconditionStrEnd(String id) {
		return "}";
	}
	
	@Override
	public String getUpdateStr(String id) {
		if(isLast) {
			return groupcnt + id + "=0;";
		} else {
			return groupcnt + id + "++;";			
		}
		
	}

	@Override
	public String getDeclarationStr(String id) {
		return "int " + groupcnt + id + " = 0;";
	}

	public void setLast(boolean b) {
		isLast = b;		
	}

}
