package com.iceberg.cbase.tokens;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import com.iceberg.cbase.parsers.Item;
import com.iceberg.cbase.parsers.PatternSorter;
import com.iceberg.cbase.parsers.ExtendedParserStruct.NameAndType;

public class TokenStruct extends ContainerToken<TokenFunctionDecl> {
	/* список функций, которые содержаться в структурах */
	
	
	private String name;
	private String type;
	
	public String getName() {
		return name;
	}

	public String getType() {
		return type;
	}
	
	public TokenStruct(String name, String type, int beginIndex, int endIndex, String content, 
			String ldvCommentContent, List<TokenFunctionDecl> functionDeclList) {
		super(beginIndex, endIndex, content, ldvCommentContent, functionDeclList);
		this.name = name;
		this.type = type;
	}

	public void setComments(List<NameAndType> fnamesPattern) {
		for(TokenFunctionDecl tfd: tokens) {
			// ищем для него соответствующий тип
			for(NameAndType nt : fnamesPattern) {
				if(nt.getName().equals(tfd.getName())) {
					tfd.setCallback(nt.getType());
					break;
				}
			}
		}
	}

	boolean sorted = false;
	
	public boolean isSorted() {
		return sorted;
	}
	
	public void sortFunctions(PatternSorter patternSorter, List<NameAndType> fnames) {
		assert sorted==false : "please do not sort twice";
		
		List<NameAndType> fnamesPattern = new ArrayList<NameAndType>(fnames);
		List<TokenFunctionDecl> decls = new ArrayList<TokenFunctionDecl>(tokens);
		
		sortedItems = patternSorter.sortByPattern(type, fnamesPattern, decls);
		
		//support old style of using sorted results through tokens field
		//List<TokenFunctionDecl> newTokens = new ArrayList<TokenFunctionDecl>(tokens.size());
		//for(Item<TokenFunctionDecl> t : sortedItems) {
		//	newTokens.add(t.getData());
		//}
		//tokens = newTokens;		
		sorted = true;
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

	public String getId() {
		return name + "_" + type;
	}
}
