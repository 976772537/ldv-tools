package com.iceberg.cbase.parsers;


import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import com.iceberg.Logger;
import com.iceberg.cbase.parsers.options.OptionFunctionName;
import com.iceberg.cbase.readers.ReaderInterface;
import com.iceberg.cbase.tokens.Token;
import com.iceberg.cbase.tokens.TokenFunctionDecl;

public class ExtendedParserFunction extends ExtendedParser {

	/**
	 *	паттерны для поиска входных параметров функци
	 *
	 */
    //private static Pattern beginPatternHigh=Pattern.compile("(^\\s*\\\\*\\s*(const\\s+)*(enum|union)\\s+[a-zA-Z_][a-zA-Z0-9_]*[\\\\*\\s]+)|(^\\s*\\\\*\\s*(const\\s+)?unsigned\\s+(int|char|double|long)?[\\\\*\\s]+)|(^\\s*\\\\*\\s*(const\\s+)?struct\\s+([a-zA-Z_][a-zA-Z0-9_]*\\s+)?[a-zA-Z_][a-zA-Z0-9_]*[\\\\*\\s]+)|(^\\s*\\\\*\\s*(const\\s+)?[&a-zA-Z_][a-zA-Z0-9_]*\\s?[\\\\*\\s]*)|(^\\s*\\\\*\\s*(const\\s+)?[a-zA-Z_][a-zA-Z0-9_]*[\\\\*\\s]+[a-zA-Z_][a-zA-Z0-9_]*[\\\\*\\s]+)");
	private static Pattern beginPatternHigh=Pattern.compile("(^\\s*\\\\*\\s*(const\\s+)*(enum|union)\\s+[a-zA-Z_][a-zA-Z0-9_]*[\\\\*\\s]+)|(^\\s*\\\\*\\s*(const\\s+)?unsigned\\s+(int|char|double|long)?[\\\\*\\s]+)|(^\\s*\\\\*\\s*(const\\s+)?struct\\s+([a-zA-Z_][a-zA-Z0-9_]*\\s+)?[a-zA-Z_][a-zA-Z0-9_]*[\\\\*\\s]+)|(^\\s*\\\\*\\s*(const\\s+)?[&a-zA-Z_][a-zA-Z0-9_]*\\s?[\\\\*\\s]*[\\\\*&a-zA-Z_]*\\\\s\\\\*[a-zA-Z0-9_])|(^\\s*\\\\*\\s*(const\\s+)?[a-zA-Z_][a-zA-Z0-9_]*[\\\\*\\s]+[a-zA-Z_][a-zA-Z0-9_]*[\\\\*\\s]+)");
	private static Pattern beginPatternHighInvert=Pattern.compile("(^\\s*\\\\*\\s*(const\\s+)*(enum|union)\\s+[a-zA-Z_][a-zA-Z0-9_]*[\\\\*\\s]+)|(^\\s*\\\\*\\s*(const\\s+)?unsigned\\s+(int|char|double|long)?[\\\\*\\s]+)|(^\\s*\\\\*\\s*(const\\s+)?struct\\s+([a-zA-Z_][a-zA-Z0-9_]*\\s+)?[a-zA-Z_][a-zA-Z0-9_]*[\\\\*\\s]+)|(^\\s*\\\\*\\s*(const\\s+)?[&a-zA-Z_][a-zA-Z0-9_]*\\s?[\\\\*\\s]*)|(^\\s*\\\\*\\s*(const\\s+)?[a-zA-Z_][a-zA-Z0-9_]*[\\\\*\\s]+[a-zA-Z_][a-zA-Z0-9_]*[\\\\*\\s]+)");
    private static Pattern endPatternHigh=Pattern.compile("([\\s\\*]*\\[[\\s\\*]*\\])?[\\s\\*]*$");
	private static Pattern beginPatternLow=Pattern.compile("^\\s*(const\\s+)?(((unsigned)||(struct))\\s+)?[a-zA-Z_][a-zA-Z0-9_]*[\\s*\\*]*\\s*\\(\\s*[\\s*\\*]*\\s*");
	private static Pattern endPatternLow=Pattern.compile("([\\s\\*]*\\[[\\s\\*]*\\])?\\)(.*\\s*)+");

	boolean parseFunctionCalls = false;

	public ExtendedParserFunction(ReaderInterface reader) {
		super(reader);
		addOption(new OptionFunctionName());
	}

	public 	void parseFunctionCallsOn() {
		this.parseFunctionCalls = true;
	}

	@Override
	protected Token parseContent(String content, int start, int end) {
		/* хаки, которые потом нужно включить по-возможности в regexpr */
		/* не должен матчииться:"PageDirty(page) && PageSwapCache(page)) {"  - */
		/* по количеству закрывающих скобок */

		if(content.indexOf(" && ")!=-1) return null;
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

		String[] sNameAndRetType = parseNameAndType(tokenClearContent);
		if (sNameAndRetType == null)
			return null;
		List<String> replacementParams = createReplacementParams(tokenClearContent,sNameAndRetType[0]);
		/* найдем реальный конец контента фукнции */
		int level = 1;
		char[] buffer = inputReader.readAll().toCharArray();
		/* из-за препроцессора количество скобок может быть нечетным */
		try {
			int localstate = 0;
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
			e.printStackTrace();
		}

		/* если установлена опция "парсить" вызовы функций, то парсим */
		List<Token> functionInnerCalls = null;
		if(this.parseFunctionCalls)
			functionInnerCalls = parseInnerCalls(this.getReader().readAll().substring(start,end));
		TokenFunctionDecl token = new TokenFunctionDecl(sNameAndRetType[0],
				sNameAndRetType[1],replacementParams,start,end,tokenClearContent,functionInnerCalls);
		return token;
	}

	/* паттерн нужен, чтобы следующей за ним функции распарсить по нему
	 * вызовы функций */
	private static Pattern fcallsPatterns = Pattern.compile("[\\w\\$]+\\s*\\([\\:\\*\\&\\w\\,\\.\\?\\%\\$\\^\\s\\=\\_\\\"\\\\\\#\\-(\\s*\\-\\s*>\\s*)\\(\\)]*\\)");
	//private static Pattern fcallsRulePatterns = Pattern.compile("[_a-zA-Z$][_a-zA-Z0-9$]*");

	private static final List<String> ckeywordsMap = new ArrayList<String>();
	static {
		ckeywordsMap.add("while");
		ckeywordsMap.add("do");
		ckeywordsMap.add("if");
		ckeywordsMap.add("else");
		ckeywordsMap.add("for");
		ckeywordsMap.add("return");
	}

	public static int parseExceptionCounter = 0;

	/* на вход подается - тело функции, вместе с заголовком "abracadanre() { if.. print.. }" */
	private static List<Token> parseInnerCalls(String buffer) {
		List<Token> tokens = new ArrayList<Token>();
		/* подготавливаем и компилим паттерны */
		Matcher matcher = fcallsPatterns.matcher(buffer.substring(buffer.indexOf('{')));
		/* матчим контент */
		/* возможно, перед тем как матчитить придется убирать
		 * блоки вида "...", иначе матчер будет брать вызовы функций и из
		 * printk- комментариев в том числе */
oWhile:		while(matcher.find()) {
			try {
				String callsString = matcher.group();
				/* оставим только имя */
				callsString = callsString.substring(0,callsString.indexOf('(')).trim();
				/* проверим имя - это действительно имя функции, а не ключевое слово */
				for(int i=0; i<ckeywordsMap.size(); i++)
					if(ckeywordsMap.get(i).equals(callsString)) continue oWhile;
				/* здесь создаем токен и отправляем в списиок */
				Token token = new Token(matcher.start(), matcher.end(), callsString, null);
				boolean isExitsts = false;

		/*		if (buffer.contains("m_extract_one_cell") && token.getContent().contains("atomic_inc")) {
					System.out.printf("m_extract_one_cell");
				}*/

				if(token!=null) {
					/* смотрим, есть ли ли уже такой токен (равный по полю контент) */
					for(int i=0; i<tokens.size(); i++) {
						if(tokens.get(i).getContent().equals(token.getContent())) {
							isExitsts = true;
							break;
						}
					}
					if(isExitsts == false)
						tokens.add(token);
				}
			} catch (Exception e) {
				Logger.debug(" parse exception - "+ ++parseExceptionCounter);
			}
		}
		return tokens;
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

	/* выделяет имя и тип возвращаемого значения функции из декларации */
	private static String[] parseNameAndType(String functionName) {
		byte[] fbname = functionName.getBytes();
		int level = 1;
		int beginName;
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
		}
		String[] result = {functionName.substring(++endName, ++beginName),rettype};
		return result;
	}

	/* разделяет параметры на строки */
	public static List<String> parseParams(String namedecl, String funname)
	{
		List<String> params=new ArrayList<String>();
		int firstSquare=namedecl.indexOf('(', namedecl.indexOf(funname));
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
