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
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.Iterator;

import org.linuxtesting.ldv.envgen.cbase.parsers.ExtendedParserStruct.NameAndType;
import org.linuxtesting.ldv.envgen.cbase.readers.ReaderInterface;
import org.linuxtesting.ldv.envgen.cbase.tokens.TokenFunctionDecl;


/**
 *
 * @author Alexander Strakh
 *
 * Парсер функций - открывает файл и ищет в нем все возможные
 * функции, код, которых находится в этом файле.
 *
 * Использует метод readAll ридера
 *
 * Может искать функции с заранее известными именами - для
 * этого необходимо вызвать меотд setPattern, до вызова
 * функции parse
 *
 */
public class ParserFunctionDecl extends Parser<TokenFunctionDecl> {
	/**
	 * 		 паттерн для поиска фукнций,
	 *  Можно добавлять исключения ключевых слов (for)|(if)
	 *
	 *   */
	private final static Pattern pattern = Pattern
		.compile("(;|})[\n\t\\s]*.*[\n\t\\s]+((?!(for)|(if))([_a-zA-Z][_a-z0-9A-Z]*))\\(.*\\)[\\s\n]*\\{");
	private final static String prePattern = "(;|})[\n\t\\s]*.*[\n\t\\s]+(";
	private final static String afterPattern = ")\\(.*\\)[\\s\n]*\\{";

	/**
	 *	паттерны для поиска входных параметров функции
	 */
	private final static Pattern beginPatternHigh=Pattern.compile("(^\\s*\\\\*\\s*(const\\s+)*(enum|union)\\s+[a-zA-Z_][a-zA-Z0-9_]*[\\\\*\\s]+)|(^\\s*\\\\*\\s*(const\\s+)?unsigned\\s+(int|char|double|long)?[\\\\*\\s]+)|(^\\s*\\\\*\\s*(const\\s+)?struct\\s+([a-zA-Z_][a-zA-Z0-9_]*\\s+)?[a-zA-Z_][a-zA-Z0-9_]*[\\\\*\\s]+)|(^\\s*\\\\*\\s*(const\\s+)?[a-zA-Z_][a-zA-Z0-9_]*[\\\\*\\s]+[a-zA-Z_][a-zA-Z0-9_]*[\\\\*\\s]+)|(^\\s*\\\\*\\s*(const\\s+)?[a-zA-Z_][a-zA-Z0-9_]*[\\\\*\\s]+)");
	private final static Pattern beginPatternHighInvert=Pattern.compile("(^\\s*\\\\*\\s*(const\\s+)*(enum|union)\\s+[a-zA-Z_][a-zA-Z0-9_]*[\\\\*\\s]+)|(^\\s*\\\\*\\s*(const\\s+)?unsigned\\s+(int|char|double|long)?[\\\\*\\s]+)|(^\\s*\\\\*\\s*(const\\s+)?struct\\s+([a-zA-Z_][a-zA-Z0-9_]*\\s+)?[a-zA-Z_][a-zA-Z0-9_]*[\\\\*\\s]+)|(^\\s*\\\\*\\s*(const\\s+)?[a-zA-Z_][a-zA-Z0-9_]*[\\\\*\\s]+)|(^\\s*\\\\*\\s*(const\\s+)?[a-zA-Z_][a-zA-Z0-9_]*[\\\\*\\s]+[a-zA-Z_][a-zA-Z0-9_]*[\\\\*\\s]+)");
	private final static Pattern endPatternHigh=Pattern.compile("([\\s\\*]*\\[[\\s\\*]*\\])?[\\s\\*]*$");
	private final static Pattern beginPatternLow=Pattern.compile("^\\s*(const\\s+)?(((unsigned)||(struct))\\s+)?[a-zA-Z_][a-zA-Z0-9_]*[\\s*\\*]*\\s*\\(\\s*[\\s*\\*]*\\s*");
	private final static Pattern endPatternLow=Pattern.compile("([\\s\\*]*\\[[\\s\\*]*\\])?\\)(.*\\s*)+");

	private List<String> patterns = null;

	public void setPatterns(List<String> patterns) {
		this.patterns = patterns;
	}

	/* парсим все декларации функций */
	public ParserFunctionDecl(ReaderInterface reader) {
		super(reader);
	}

	/* ищем все определения функции */
	@Override
	public List<TokenFunctionDecl> parse() {
		List<TokenFunctionDecl> tlist = new ArrayList<TokenFunctionDecl>();
		String buffer = null;
		buffer = inputReader.readAll();
		Matcher m = null;
		/* если список паттернов названий не установлен - то ищем все функции */
		if (patterns == null) {
			m = pattern.matcher(buffer);
		} /* иначе порходимcя по всему списку паттернов для этого файла */
		else if (patterns.size() > 0) {
			/* собираем паттерн */
			StringBuffer localPattern = new StringBuffer(prePattern);
			Iterator<String> patternIterator = patterns.iterator();
			while (patternIterator.hasNext()) {
				localPattern.append(patternIterator.next());
				if (patternIterator.hasNext())
					localPattern.append("|");
			}
			localPattern.append(afterPattern);
			Pattern lPattern = Pattern.compile(localPattern.toString());
			m = lPattern.matcher(buffer);
		}

		/* матчим */
		if (m != null)
			while (m.find()) {
				String tokenContent = m.group();
				assert tokenContent != null
						&& tokenContent.length() > 4
						&& (tokenContent.charAt(0) == ';' || tokenContent.charAt(0) == '}')
						&& (tokenContent.charAt(tokenContent.length() - 1)) == '{' : "\nЕсли регулярное выражение заматчило строку, то это значит, что она отвечает условиям:"
						+ "\n\t1) она не равна null"
						+ "\n\t2) содержит как минимум пять символов:  ; или },любой_хотябы_один,(,),{"
						+ "\n\t3) нулевой сивол - ; или }"
						+ "\n\t4) последний символ {\n";
				String tokenClearContent = tokenContent.substring(	1, tokenContent.length() - 2).trim();
				NameAndType sNameAndRetType = parseNameAndType(tokenClearContent);
				List<String> replacementParams = createReplacementParams(tokenClearContent);
				TokenFunctionDecl token = new TokenFunctionDecl(sNameAndRetType.getName(),
						sNameAndRetType.getType(),replacementParams,m.start(),m.end(),tokenClearContent ,null,null);
				tlist.add(token);
			}
		return tlist;
	}

	private static List<String> createReplacementParams(String tokenClearContent) {
		List<String> params = parseParams(tokenClearContent);
 		List<String> replacementParams = new ArrayList<String>();
		Iterator<String> paramsIterator = params.iterator();
		while(paramsIterator.hasNext()) {
			String replacementParam = createParamReplacePattern(paramsIterator.next());
			replacementParams.add(replacementParam);
		}
		return replacementParams;
	}

	/* выделяет имя и тип возвращаемого значения функции из декларации */
	private static NameAndType parseNameAndType(String functionName) {
		byte[] fbname = functionName.getBytes();
		int level = 1;
		int beginName;
		/* проскакиваем параметры функции */
		for(beginName=functionName.length()-2; level!=0 && beginName>0; beginName--) {
			if(fbname[beginName]==')') level++;
			if(fbname[beginName]=='(') level--;
		}
		/* идем по имени функции до первого порбела */
		int endName = beginName;
		while(fbname[endName]!='\n' && fbname[endName]!=' ' && endName>=0) endName--;
		return new NameAndType(functionName.substring(++endName, ++beginName),functionName.substring(0, endName).trim());
	}

	/* разделяет параметры на строки */
	public static List<String> parseParams(String namedecl)
	{
		List<String> params=new ArrayList<String>();
		int firstSquare=namedecl.indexOf('(');
		if(firstSquare==-1) return null;
		int level=0;
		char symbol=0;
		for(int i=firstSquare+1; i<namedecl.length(); i++)
		{
			symbol=namedecl.charAt(i);
			switch (symbol) {
				case '(' :
					level++;
					break;
				case ')' :
					if(level==0) {
						params.add(namedecl.substring(firstSquare+1,i));
						firstSquare=i;
					} else level--;
					break;
				case ',' :
					if(level==0) {
						params.add(namedecl.substring(firstSquare+1,i));
						firstSquare=i;
					}
					break;
			}
		}
		return params;
	}

	/*  создает из кажого параметра строку - шаблон, котоорый можно заменить на определенный параметр */
	public static String createParamReplacePattern(String param) {
		if(param.trim().equals("...") || param.trim().equals("void")) return param;
		/* ... */
		if(param.indexOf('(')==-1) {
			Matcher beginMatcher = null;
			if(param.contains("__user") || param.contains("enum") || param.contains("__iomem"))
				beginMatcher = beginPatternHigh.matcher(param);
			else beginMatcher = beginPatternHighInvert.matcher(param);

			if(param.contains("PMF_STD_ARGS")) {
				return "PMF_STD_ARGS $var";
			} else {
			beginMatcher.find();
			String pBegin=beginMatcher.group();
			Matcher endMatcher = endPatternHigh.matcher(param.substring(pBegin.length()));
			endMatcher.find();
			String pEnd=endMatcher.group();
			if(pEnd.contains("["))
				return pBegin+"* $var";
			else
				return pBegin+" $var "+pEnd;
			}
		} else
		{
			Matcher beginMatcher = beginPatternLow.matcher(param);
			beginMatcher.find();
			String pBegin=beginMatcher.group();
			Matcher endMatcher = endPatternLow.matcher(param.substring(pBegin.length()));
			endMatcher.find();
			String pEnd=endMatcher.group();
			return (pBegin+" $var "+pEnd);
		}
	}
}
