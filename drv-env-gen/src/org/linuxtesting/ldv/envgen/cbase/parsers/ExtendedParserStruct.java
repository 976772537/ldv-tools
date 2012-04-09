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
package org.linuxtesting.ldv.envgen.cbase.parsers;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Properties;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.linuxtesting.ldv.envgen.Logger;
import org.linuxtesting.ldv.envgen.cbase.parsers.options.OptionStructType;
import org.linuxtesting.ldv.envgen.cbase.readers.ReaderInterface;
import org.linuxtesting.ldv.envgen.cbase.tokens.TokenStruct;
import org.linuxtesting.ldv.envgen.cbase.tokens.TokenFunctionDecl;


public class ExtendedParserStruct extends ExtendedParser<TokenStruct> {

	public static final char KEY_TAB = 9;
	public static final char KEY_NEW_LINE = 10;
	public static final char KEY_CARRIER_RET = '\r';
	public static final char KEY_SPACE = ' ';
	public static final char KEY_1 = '{';
	public static final char KEY_2 = '(';
	public static final char KEY_3 = '=';
	public static final char KEY_4 = '+';
	public static final char KEY_5 = '-';
	public static final char KEY_N1 = '1';
	public static final char KEY_N2 = '2';
	public static final char KEY_N3 = '3';
	public static final char KEY_N4 = '4';
	public static final char KEY_N5 = '5';
	public static final char KEY_N6 = '6';
	public static final char KEY_N7 = '7';
	public static final char KEY_N8 = '8';
	public static final char KEY_N9 = '9';
	public static final char KEY_N10 = '0';

	/* если 1 - то используем механизм поиска шаблонов */
	private boolean sortFunctionCalls = true;
	Map<String,TokenFunctionDecl> parsedFunctions;
	
	public void setSortFunctionCalls(boolean b) {
		this.sortFunctionCalls = b;
	}
	
	private PatternSorter patternSorter;
	
	public PatternSorter getPatternSorter() {
		return patternSorter;
	}

	public ExtendedParserStruct(Properties properties, ReaderInterface reader, Map<String,TokenFunctionDecl> parsedFunctions) {
		super(reader);
		addOption(new OptionStructType());
		if(properties!=null) {
			patternSorter = new PatternSorter(properties);
		} else {
			patternSorter = new PatternSorter();			
		}
		this.parsedFunctions = parsedFunctions;
	}

	public ExtendedParserStruct(ReaderInterface reader) {
		this(null, reader, null);
	}
	
	/**
	 * Parses 
	 */
	@Override
	protected TokenStruct parseContent(String content, int start, int end) {
		String buffer = getReader().readAll();
		String tokenClearContent = content.trim();
		NameAndType sNameAndType = parseNameAndType(tokenClearContent);
		// посчитаем действительный конец структуры
		int level = 1;
		int nend;
		for(nend = end; level!=0 ; nend++) {
			if(buffer.charAt(nend)=='{') level++;
			if(buffer.charAt(nend)=='}') level--;
		}
		String innerContent = buffer.substring(end,--nend).trim();
		/**
		 *  распарсим спсиок вложенных функций -
		 *  часть функций из старого парсера ! - убрать
		 *  */
		Logger.trace("Content of struct initialization: " + innerContent);
		/* найдем все предполагаемые имена функций в структуре */
		List<NameAndType> fnames = getFunctionNames(innerContent);
		Logger.trace("TokenStruct.parseContent " + sNameAndType + " initialized as " + fnames);
		if(fnames.size()>0) {
			List<TokenFunctionDecl> functions;
			if(parsedFunctions==null) {
				Logger.debug("parse functions");
				/* создадим парсер функций */
				ExtendedParserFunction innerParserFunctions = new ExtendedParserFunction(getReader());
				/* и добавим в него поиск только по указанным именам функций */
				for(NameAndType fnamesIterator : fnames) {
					/* TODO: сделать метод добавления множества параметров */
					innerParserFunctions.addConfigOption("name", fnamesIterator.getName());
				}
				/* и запустим парсер */
				functions = innerParserFunctions.parse();
			} else {
				Logger.debug("use parsed functions table");
				functions = new ArrayList<TokenFunctionDecl>(fnames.size()); 
				for(NameAndType fnamesIterator : fnames) {
					TokenFunctionDecl tfd = parsedFunctions.get(fnamesIterator.getName());
					if(tfd!=null) {
						if(!isExists(functions, tfd)) {
							functions.add(tfd);
						} else {
							Logger.debug("duplicated function tfd=" + tfd.getName());
						}
					} else {
						Logger.debug("Not found declaration for name " + fnamesIterator.getName());
					}
				}				
			}
			Logger.trace("TokenStruct.parsed funcs " + functions);
			Logger.debug("TokenStruct.parseContent: Found " + functions.size() + " out of " + fnames.size() + " functions");
			/* и создадим токен - структуру */
			TokenStruct token = new TokenStruct(sNameAndType.getName(), sNameAndType.getType(),
					start, nend, tokenClearContent, null, functions);
			
			if(this.sortFunctionCalls) {
				/* отсортируем по шаблону */
				token.sortFunctions(patternSorter, fnames);
			} 
			/* установим ldvCommentContent */
			token.setComments(fnames);
			
			Logger.trace("TokenStruct.parsed funcs after sort" + functions);
			return token;
		}
		return null;
	}

	private boolean isExists(List<TokenFunctionDecl> functions,
			TokenFunctionDecl tfd) {
		String name = tfd.getName();
		for(TokenFunctionDecl d : functions) {
			if(name.equals(d.getName())) {
				return true;
			}
		}
		return false;
	}

	public static NameAndType parseNameAndType(String clearContent) {
		String typeName = clearContent.substring(clearContent.indexOf("struct")+6).trim();
		typeName = typeName.substring(0,typeName.indexOf(' ')).trim();
		String structName = clearContent.substring(clearContent.indexOf(typeName)+typeName.length(),clearContent.indexOf('=')).trim();
		return new NameAndType(structName,typeName); 
	}

	public static class NameAndType {
		String name;
		String type;
		public NameAndType(String name, String type) {
			super();
			this.name = name;
			this.type = type;
		}
		public String getName() {
			return name;
		}
		public String getType() {
			return type;
		}		
		@Override
		public String toString() {
			return "NameAndType [name=" + name + ", type=" + type + "]";
		}
	}
	
	private final static Pattern fstruct = Pattern.compile("\\.[_a-zA-Z][_a-zA-Z0-9]*\\s*=\\s*[_a-zA-Z][_a-zA-Z0-9]*");
	
	public static List<NameAndType> getFunctionNames(String buffer)
	{
		List<NameAndType> functions = new ArrayList<NameAndType>();
		Matcher lmatcher = fstruct.matcher(buffer);
		while(lmatcher.find()) {
			String lfinded = lmatcher.group();
			Logger.trace("lfinded=" + lfinded);
			int lindex = lfinded.indexOf('=');
			String ltype = lfinded.substring(1,lindex).trim();
			String lname = lfinded.substring(lindex+1,lfinded.length()).trim();
			NameAndType nt = new NameAndType(lname,ltype);
			Logger.trace("" + nt);
			functions.add(nt);
		}
		return functions;
	}

	public static String getPtrnContentFromIndex(String buffer, String beginptrn, String endptrn, int fromIndex)
	{
		int toIndex;
		if((fromIndex=buffer.indexOf(beginptrn, fromIndex))>=0 && (toIndex=buffer.indexOf(endptrn,  fromIndex))>=0 && fromIndex<toIndex)
		{
			return buffer.substring(fromIndex+beginptrn.length(), toIndex);
		}
		return null;
	}
}
