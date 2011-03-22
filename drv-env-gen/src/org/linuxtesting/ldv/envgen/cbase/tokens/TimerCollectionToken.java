package org.linuxtesting.ldv.envgen.cbase.tokens;

import java.util.ArrayList;
import java.util.List;

import org.linuxtesting.ldv.envgen.cbase.parsers.Item;
import org.linuxtesting.ldv.envgen.cbase.parsers.TimerItem;

public class TimerCollectionToken extends TokenFuncCollection {

	private String name;

	public TimerCollectionToken(String name, String ldvCommentContent,
			List<TokenFunctionDecl> tokens) {
		super(name, ldvCommentContent, tokens);
		sortedItems = new ArrayList<Item<TokenFunctionDecl>>();
		for(TokenFunctionDecl tfd : tokens) {
			sortedItems.add(new TimerItem<TokenFunctionDecl>(tfd));
		}
		this.sorted = true;
		this.name = name;
	}

	@Override
	public String getDesc() {
		return "TIMER SECTION " + name;
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
