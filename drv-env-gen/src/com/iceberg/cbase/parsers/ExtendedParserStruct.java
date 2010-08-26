package com.iceberg.cbase.parsers;

import java.util.ArrayList;
import java.util.List;
import java.util.Iterator;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import com.iceberg.cbase.parsers.options.OptionStructType;
import com.iceberg.cbase.readers.ReaderInterface;
import com.iceberg.cbase.tokens.Token;
import com.iceberg.cbase.tokens.TokenFunctionDecl;
import com.iceberg.cbase.tokens.TokenStruct;

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
	private int patternCallQueue = 1;

	public void offPatternCallQueue() {
		this.patternCallQueue = 0;
	}

	public ExtendedParserStruct(ReaderInterface reader) {
		super(reader);
		addOption(new OptionStructType());
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
		/* найдем все предполагаемые имена функций в структуре */
		List<NameAndType> fnames = getFunctionNames(innerContent,this.patternCallQueue);
		TokenStruct token = null;
		if(fnames.size()>0) {
			/* создадим парсер функций */
			ExtendedParserFunction innerParserFunctions = new ExtendedParserFunction(getReader());
			/* и добавим в него поиск только по указанным именам функций */
			Iterator<NameAndType> fnamesIterator = fnames.iterator();
			/* TODO: сделать метод добавления множества параметров */
			while(fnamesIterator.hasNext())
				innerParserFunctions.addConfigOption("name", fnamesIterator.next().getName());
			/* и запустим парсер */
			List<TokenFunctionDecl> functions = innerParserFunctions.parse();
			/* отсортируем по шаблону */
			List<TokenFunctionDecl> sortedFunctions;
			List<NameAndType> fnamesPattern = new ArrayList<NameAndType>(fnames);
			if( this.patternCallQueue == 1)
				sortedFunctions = PatternSort.sortByPattern(sNameAndType.getType(), fnames, functions);
			else
				sortedFunctions = functions;
			/* установим ldvCommentContent */
			for(Token itoken: sortedFunctions) {
				if(itoken instanceof TokenFunctionDecl) {
					TokenFunctionDecl tfd = (TokenFunctionDecl)itoken;
					// ищем для него соответствующий тип
					for(int i=0; i<fnamesPattern.size(); i++) {
						if(fnamesPattern.get(i).getName().equals(tfd.getName())) {
							tfd.setCallback(fnamesPattern.get(i).getType());
							break;
						}
					}
				}
			}
			
			/* и создадим токен - структуру */
			token = new TokenStruct(sNameAndType.getName(), sNameAndType.getType(),
					start, nend, tokenClearContent, null, sortedFunctions);
		}
		return token;
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
	}
	
	private static Pattern fstruct = Pattern.compile("\\.[_a-zA-Z][_a-zA-Z0-9]*\\s*=\\s[_a-zA-Z][_a-zA-Z0-9]*");
	
	public static List<NameAndType> getFunctionNames(String buffer, int patternCallQueue)
	{
		List<NameAndType> functions = new ArrayList<NameAndType>();
		Matcher lmatcher = fstruct.matcher(buffer);
		String lfinded;
		String lname;
		String ltype;
		int lindex;
		while(lmatcher.find()) {
			lfinded = lmatcher.group();
			lindex = lfinded.indexOf('=');
			ltype = lfinded.substring(1,lindex).trim();
			lname = lfinded.substring(lindex+1,lfinded.length()).trim();
			functions.add(new NameAndType(lname,ltype));
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
