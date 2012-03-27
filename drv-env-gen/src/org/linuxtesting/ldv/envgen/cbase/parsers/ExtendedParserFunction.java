/*
 * Copyright 2010-2012
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
import java.util.Iterator;
import java.util.LinkedList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.linuxtesting.ldv.envgen.Logger;
import org.linuxtesting.ldv.envgen.cbase.parsers.ExtendedParserStruct.NameAndType;
import org.linuxtesting.ldv.envgen.cbase.parsers.options.OptionFunctionName;
import org.linuxtesting.ldv.envgen.cbase.readers.ReaderInterface;
import org.linuxtesting.ldv.envgen.cbase.tokens.TokenBodyElement;
import org.linuxtesting.ldv.envgen.cbase.tokens.TokenFunctionDecl;


public class ExtendedParserFunction extends ExtendedParser<TokenFunctionDecl> {

	/**
	 *	паттерны для поиска входных параметров функци
	 *
	 */
    //private final static Pattern beginPatternHigh=Pattern.compile("(^\\s*\\\\*\\s*(const\\s+)*(enum|union)\\s+[a-zA-Z_][a-zA-Z0-9_]*[\\\\*\\s]+)|(^\\s*\\\\*\\s*(const\\s+)?unsigned\\s+(int|char|double|long)?[\\\\*\\s]+)|(^\\s*\\\\*\\s*(const\\s+)?struct\\s+([a-zA-Z_][a-zA-Z0-9_]*\\s+)?[a-zA-Z_][a-zA-Z0-9_]*[\\\\*\\s]+)|(^\\s*\\\\*\\s*(const\\s+)?[&a-zA-Z_][a-zA-Z0-9_]*\\s?[\\\\*\\s]*)|(^\\s*\\\\*\\s*(const\\s+)?[a-zA-Z_][a-zA-Z0-9_]*[\\\\*\\s]+[a-zA-Z_][a-zA-Z0-9_]*[\\\\*\\s]+)");
	private final static Pattern beginPatternHigh=Pattern.compile("(^\\s*\\\\*\\s*(const\\s+)*(enum|union)\\s+[a-zA-Z_][a-zA-Z0-9_]*[\\\\*\\s]+)|(^\\s*\\\\*\\s*(const\\s+)?unsigned\\s+(int|char|double|long)?[\\\\*\\s]+)|(^\\s*\\\\*\\s*(const\\s+)?struct\\s+([a-zA-Z_][a-zA-Z0-9_]*\\s+)?[a-zA-Z_][a-zA-Z0-9_]*[\\\\*\\s]+)|(^\\s*\\\\*\\s*(const\\s+)?[&a-zA-Z_][a-zA-Z0-9_]*\\s?[\\\\*\\s]*[\\\\*&a-zA-Z_]*\\\\s\\\\*[a-zA-Z0-9_])|(^\\s*\\\\*\\s*(const\\s+)?[a-zA-Z_][a-zA-Z0-9_]*[\\\\*\\s]+[a-zA-Z_][a-zA-Z0-9_]*[\\\\*\\s]+)");
	private final static Pattern beginPatternHighInvert=Pattern.compile("(^\\s*\\\\*\\s*(const\\s+)*(enum|union)\\s+[a-zA-Z_][a-zA-Z0-9_]*[\\\\*\\s]+)|(^\\s*\\\\*\\s*(const\\s+)?unsigned\\s+(int|char|double|long)?[\\\\*\\s]+)|(^\\s*\\\\*\\s*(const\\s+)?struct\\s+([a-zA-Z_][a-zA-Z0-9_]*\\s+)?[a-zA-Z_][a-zA-Z0-9_]*[\\\\*\\s]+)|(^\\s*\\\\*\\s*(const\\s+)?[&a-zA-Z_][a-zA-Z0-9_]*\\s?[\\\\*\\s]*)|(^\\s*\\\\*\\s*(const\\s+)?[a-zA-Z_][a-zA-Z0-9_]*[\\\\*\\s]+[a-zA-Z_][a-zA-Z0-9_]*[\\\\*\\s]+)");
    private final static Pattern endPatternHigh=Pattern.compile("([\\s\\*]*\\[[\\s\\*]*\\])?[\\s\\*]*$");
	private final static Pattern beginPatternLow=Pattern.compile("^\\s*(const\\s+)?(((unsigned)||(struct))\\s+)?[a-zA-Z_][a-zA-Z0-9_]*[\\s*\\*]*\\s*\\(\\s*[\\s*\\*]*\\s*");
	private final static Pattern endPatternLow=Pattern.compile("([\\s\\*]*\\[[\\s\\*]*\\])?\\)(.*\\s*)+");

	private List<FunctionBodyParser> bodyParsers = new LinkedList<FunctionBodyParser>();
	
	//private boolean parseInnerFunctionCalls = false;

	public ExtendedParserFunction(ReaderInterface reader) {
		super(reader);
		addOption(new OptionFunctionName());
	}

	public void addBodyParser(FunctionBodyParser parser) {
		bodyParsers.add(parser);
	}

	public void addAllBodyParser(List<FunctionBodyParser> parsers) {
		bodyParsers.addAll(parsers);
	}
	
	@Override
	protected TokenFunctionDecl parseContent(String content, int start, int end) {
		/* хаки, которые потом нужно включить по-возможности в regexpr */
		/* не должен матчииться:"PageDirty(page) && PageSwapCache(page)) {"  - */
		/* по количеству закрывающих скобок */
		//Logger.trace("The content is " + content);
		if(content.indexOf(" && ")!=-1) {
			Logger.debug("Hack. Ignore &&: " + content);
			return null;
		}
		/*
		 * вырежем GNU расширения из имени
		 */
		/*if(content.indexOf("releases")!=-1) {
			System.out.println();
		}*/
		content = content.replaceFirst("(__releases|__acquires)\\(.*\\)", "");

		String tokenClearContent = null;
		int indexdot = content.indexOf(';');
		if(indexdot!=-1) {
			if(content.charAt(content.length()-1)==' ')
				tokenClearContent = content.substring(indexdot+1, content.length() - 2).trim().replaceAll("\\s{2,}|\\n"," ");
			else
				tokenClearContent = content.substring(indexdot+1, content.length() - 1).trim().replaceAll("\\s{2,}|\\n"," ");
			start += indexdot+1;
		}
		else {
			if(content.charAt(content.length()-1)==' ')
				tokenClearContent = content.substring(1, content.length() - 2).trim().replaceAll("\\s{2,}|\\n"," ").replaceAll("\\)\\s+__releases\\(\\s*[a-zA-Z_\\$][a-zA-Z0-9_\\$]*\\s*\\)", ")");
			else
				tokenClearContent = content.substring(1, content.length() - 1).trim().replaceAll("\\s{2,}|\\n"," ").replaceAll("\\)\\s+__releases\\(\\s*[a-zA-Z_\\$][a-zA-Z0-9_\\$]*\\s*\\)", ")");
			start++;
		}

		NameAndType sNameAndRetType = parseNameAndType(tokenClearContent);
		if (sNameAndRetType == null) {
			Logger.debug("Name and type not found " + tokenClearContent);
			return null;			
		}
		List<String> replacementParams = createReplacementParams(tokenClearContent,sNameAndRetType.getName());
		/* найдем реальный конец контента фукнции */
		/* из-за препроцессора количество скобок может быть нечетным */
		try {
			int localstate = 0;
			int level = 1;
			char[] buffer = inputReader.readAll().toCharArray();
			for(; level!=0; end++) {
				/* возможны проблемы со строками, содержащими экранирование */
				/**
				 * Если в теле функции встречается конструкция #ifdef ... #endif,
				 * и внутри блок, который содержит дополнительную скобку {  - то
				 * алгоритм посика конца функции накрывается...
				 * Посему, если встречаем директиву препроцессора внутри функции,
				 * то определяем относится ли она к ifdef и есть ли у нее else,
				 * если да, то выбираем только один блок */
				/* проверяем - это директива препроцессора ? */
				if(end>0 && buffer[end]=='#' && buffer[end-1]=='\n') {
					/* проскочим whitespace символы */
					int lend = end + 1;
					while(buffer[lend]==' ' || buffer[lend]=='\t') lend++;
					/* определяем блоки */
					if(buffer[lend]=='i' && buffer[++lend]=='f') {
						/* устанавливаем состояние - "начался первый блок" */
						localstate = 0;
						/* идем до конца директивы препроцессора */
						lend++;
						while(!(buffer[lend]=='\n' && buffer[lend-1]!='\\')) lend++;
						end = lend;
					} else
					if((lend+4)<buffer.length && buffer[lend]=='e' && buffer[lend+1]=='l' && buffer[lend+2]=='s' && buffer[lend+3]=='e') {
						assert(localstate == 0) : "до блока else обязательно должен был быть if***!";
						/* устанавливаем состояние - "начался альтернативный блок" */
						localstate = 1;
						/* идем до конца директивы препроцессора */
						lend+=4;
						while(!(buffer[lend]=='\n' && buffer[lend-1]!='\\')) lend++;
						end = lend;
					}
					if((lend+3)<buffer.length && buffer[lend]=='e' && buffer[lend+1]=='n' && buffer[lend+2]=='d') {
						/* устанавливаем состояние - "конец блока препроцессора" */
						localstate = 0;
						/* идем до конца директивы препроцессора */
						lend+=3;
						while(!(buffer[lend]=='\n' && buffer[lend-1]!='\\')) lend++;
						end = lend;
					}
				}
				/* считаем скобки, только, если мы не в альтернативаном блоке препроцессора */
				if(localstate == 0 ) {
					if(buffer[end]=='{' && buffer[end-1]!='\\') level++;
					if(buffer[end]=='}' && buffer[end-1]!='\\') level--;
				}
			}
		} catch(Exception e) {
			Logger.warn("Function end not found: " +  sNameAndRetType + "\n Exception: " + e);
			e.printStackTrace();
		}

		Logger.trace("Parse inner calls for " + sNameAndRetType);
		String buffer = this.getReader().readAll().substring(start,end);
		List<TokenBodyElement> bodyElements = new LinkedList<TokenBodyElement>();
		for(FunctionBodyParser parser : bodyParsers) {
			List<TokenBodyElement> list = parser.parse(buffer);
			Logger.trace("Parsed elements " + list.size());
			bodyElements.addAll(list);
		}
		TokenFunctionDecl token = new TokenFunctionDecl(sNameAndRetType.getName(),
				sNameAndRetType.getType(),replacementParams,start,end,tokenClearContent,null,bodyElements);
		return token;
	}

	private static List<String> createReplacementParams(String tokenClearContent, String funname) {
		List<String> params = parseParams(tokenClearContent, funname);
 		List<String> replacementParams = new ArrayList<String>();
		Iterator<String> paramsIterator = params.iterator();
		while(paramsIterator.hasNext()) {
			String repParam = paramsIterator.next();
			if(repParam.length()!=0) {
				String replacementParam = createParamReplacePattern(repParam);
				replacementParams.add(replacementParam);
			}
			//String replacementParam = createParamReplacePattern(paramsIterator.next());
		}
		return replacementParams;
	}

	/**
	 *  выделяет имя и тип возвращаемого значения функции из декларации 
	 *  name - function name
	 *  type - return type   
	 */
	private static NameAndType parseNameAndType(String functionName) {
		byte[] fbname = functionName.getBytes();
		int level = 1;
		int beginName;
		Logger.trace("Function name (" + functionName.length() + "):" + functionName);
		if(functionName.length()<2) {
			Logger.warn("Empty function name " + functionName);
			return null;
		}
		/* проскакиваем параметры функции */
		for(beginName=functionName.length()-2; level!=0 && beginName>0; beginName--) {
			if(fbname[beginName]==')') level++;
			if(fbname[beginName]=='(') level--;
		}
		/* порскачкиваем пробелы */
		while(fbname[beginName]==' ' || fbname[beginName]=='\n')
			beginName--;
		/* идем по имени функции до первого пробела */
		int endName = beginName;
		while(endName!=-1 && fbname[endName]!='\n' && fbname[endName]!=' ' && endName>=0) {
			//System.out.println((char)fbname[endNmae]);
			if(fbname[endName]=='*')
				break;
			endName--;
		}
		if(endName == -1)
			return null;
		String rettype = functionName.substring(0, endName).trim();
		/*
		 * код для удаления модификаторов GNU-C для возвращаемого параметра
		 * (описани епеременных поризводится без использования модификаторов)
		 * */
		if(rettype!=null && rettype.length()>0) {
			rettype = rettype.replaceAll("__init", "");
			rettype = rettype.replaceAll("__exit", "");
			rettype = rettype.replaceAll("__devinit", "");
			rettype = rettype.replaceAll("__devexit", "");
			rettype = rettype.replaceAll("__cpuinit", "");
			rettype = rettype.replaceAll("__cpuexit", "");
			rettype = rettype.replaceAll("__meminit", "");
			rettype = rettype.replaceAll("__memexit", "");
			/**/
		}
		return new NameAndType(functionName.substring(++endName, ++beginName),rettype);
	}

	/* разделяет параметры на строки */
	public static List<String> parseParams(String namedecl, String funname)
	{
		List<String> params=new ArrayList<String>();
		int firstSquare=namedecl.indexOf('(', namedecl.indexOf(funname));
		if(firstSquare==-1) return null;
		int level=0;
		char symbol=0;
		int prev = firstSquare;
		for(int i=prev+1; i<namedecl.length(); i++)
		{
			symbol=namedecl.charAt(i);
			switch (symbol) {
				case '(' :
					level++;
					break;
				case ')' :
					if(level==0) {
						String s = namedecl.substring(prev+1,i);
						params.add(s.trim());
						prev=i;
					} else {
						level--;
						if(level<0) {
							Logger.warn("Too many closing braces in " + namedecl);
							Logger.debug("Level is less than zero, level=" + level);
							Logger.debug("prev=" + prev);
							Logger.debug("i=" + i);
						}
					}
					break;
				case ',' :
					if(level==0) {
						String s = namedecl.substring(prev+1,i);
						params.add(s.trim());
						prev=i;
					}
					break;
			}
		}
		return params;
	}

	/*  создает из кажого параметра строку - шаблон, который можно заменить на определенный параметр */
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
			//assert beginMatcher.find() : "параметр функции должен матчииться в любом случае..." +param +"\n";
			/* параметр функции матчиитьмся не в любом случае, например, если
			 * имя перемнной отсутстсвует */
			String pBegin = null;
			Matcher endMatcher = null;
			if(beginMatcher.find()) {
				pBegin=beginMatcher.group();
				endMatcher = endPatternHigh.matcher(param.substring(pBegin.length()));
			} else {
				pBegin="";
				endMatcher = endPatternHigh.matcher(param);
			}
			endMatcher.find();
			String pEnd=endMatcher.group();
			if(pEnd.contains("["))
				return pBegin+"* $var";
			else
				return pBegin+" $var " + pEnd;
			}
		} else {
			Matcher beginMatcher = beginPatternLow.matcher(param);
			beginMatcher.find();

			/*  может function init в параметрах а может - просто отсутствия имени в параметре */
			String pBegin = null;
			try {
				pBegin=beginMatcher.group();
			} catch(Exception e) {
				Logger.err("begin match: function init in params: " + param);
			}

			Matcher endMatcher = endPatternLow.matcher(param.substring(pBegin.length()));
			endMatcher.find();
			String pEnd = null;

			try {
				pEnd = endMatcher.group();
			} catch(Exception e) {
				Logger.err("end match: function init in params: " + param);
			}

			return (pBegin+" $var "+pEnd);
		}
	}
}
