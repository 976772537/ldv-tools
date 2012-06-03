/*
 * Copyright (C) 2010-2012
 * Institute for System Programming, Russian Academy of Sciences (ISPRAS).
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
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
