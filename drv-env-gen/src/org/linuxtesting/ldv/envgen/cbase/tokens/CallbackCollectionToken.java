package org.linuxtesting.ldv.envgen.cbase.tokens;

import java.util.ArrayList;
import java.util.List;

import org.linuxtesting.ldv.envgen.cbase.parsers.CallbackItem;
import org.linuxtesting.ldv.envgen.cbase.parsers.Item;

public class CallbackCollectionToken extends TokenFuncCollection {
	private String name;

	public CallbackCollectionToken(String name, String ldvCommentContent,
			List<TokenFunctionDecl> tokens) {
		super(name, ldvCommentContent, tokens);
		sortedItems = new ArrayList<Item<TokenFunctionDecl>>();
		for(TokenFunctionDecl tfd : tokens) {
			sortedItems.add(new CallbackItem<TokenFunctionDecl>(tfd));
		}
		this.sorted = true;
		this.name = name;
	}

	@Override
	public String getDesc() {
		return "CALLBACK SECTION " + name;
	}

	@Override
	public String getId() {
		return name;
	}

	@Override
	public String getName() {
		return name;
	}

}
