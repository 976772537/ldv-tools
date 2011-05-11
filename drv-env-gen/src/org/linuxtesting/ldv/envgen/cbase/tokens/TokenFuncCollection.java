package org.linuxtesting.ldv.envgen.cbase.tokens;

import java.util.HashSet;
import java.util.List;
import java.util.Set;

import org.linuxtesting.ldv.envgen.Logger;
import org.linuxtesting.ldv.envgen.cbase.parsers.Item;


public abstract class TokenFuncCollection extends ContainerToken<TokenFunctionDecl> {
	/* список функций, которые содержатся в структурах */
	
	public TokenFuncCollection(String content, String ldvCommentContent,
			List<TokenFunctionDecl> tokens) {
		super(content, ldvCommentContent, tokens);
	}

	boolean sorted = false;
	
	public boolean isSorted() {
		return sorted;
	}
	
	protected List<Item<TokenFunctionDecl>> sortedItems;
	
	public List<Item<TokenFunctionDecl>> getSortedTokens() {
		return sortedItems;
	}
	
	public String getDeclStr(String indent) {
		Set<String> s = new HashSet<String>();
		StringBuffer buf = new StringBuffer();
		for(Item<TokenFunctionDecl> t : sortedItems) {
			String itemDecl = t.getDeclarationStr(getId());
			if(s.add(itemDecl)) {
				buf.append(indent + itemDecl + "\n");				
			}
		}
		return buf.toString();
	}

	public String getCompletionCheckStr() {
		Set<String> s = new HashSet<String>();
		StringBuffer buf = new StringBuffer();
		boolean first = true;
		for(Item<TokenFunctionDecl> t : sortedItems) {
			String itemCheck = t.getCompletionCheckStr(getId());
			Logger.trace("itemCheck=" + itemCheck);
			//ignore empty checks
			if(itemCheck!=null && !itemCheck.trim().isEmpty() && s.add(itemCheck)) {
				if(!first) {
					buf.append(" || ");					
				}
				buf.append(itemCheck);				
				first = false;
			}
		}
		return buf.toString();
	}
	
	public abstract String getDesc();
	public abstract String getId();
	public abstract String getName();
}
