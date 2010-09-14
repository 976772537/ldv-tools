package org.linuxtesting.ldv.envgen.cbase.parsers;

import java.util.ArrayList;
import java.util.List;
import java.util.Properties;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.linuxtesting.ldv.envgen.Logger;
import org.linuxtesting.ldv.envgen.cbase.parsers.options.OptionStructType;
import org.linuxtesting.ldv.envgen.cbase.readers.ReaderInterface;
import org.linuxtesting.ldv.envgen.cbase.tokens.TokenFunctionDecl;
import org.linuxtesting.ldv.envgen.cbase.tokens.TokenStruct;


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

	public void setSortFunctionCalls(boolean b) {
		this.sortFunctionCalls = b;
	}
	
	private PatternSorter patternSorter;
	
	public PatternSorter getPatternSorter() {
		return patternSorter;
	}

	public ExtendedParserStruct(Properties properties, ReaderInterface reader) {
		super(reader);
		addOption(new OptionStructType());
		if(properties!=null) {
			patternSorter = new PatternSorter(properties);
		} else {
			patternSorter = new PatternSorter();			
		}
	}

	public ExtendedParserStruct(ReaderInterface reader) {
		this(null, reader);
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
		List<NameAndType> fnames = getFunctionNames(innerContent);
		Logger.trace("TokenStruct.parseContent " + sNameAndType + " functions " + fnames);
		if(fnames.size()>0) {
			/* создадим парсер функций */
			ExtendedParserFunction innerParserFunctions = new ExtendedParserFunction(getReader());
			/* и добавим в него поиск только по указанным именам функций */
			for(NameAndType fnamesIterator : fnames) {
				/* TODO: сделать метод добавления множества параметров */
				innerParserFunctions.addConfigOption("name", fnamesIterator.getName());
			}
			/* и запустим парсер */
			List<TokenFunctionDecl> functions = innerParserFunctions.parse();
			Logger.trace("TokenStruct.parsed funcs " + functions);
						
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
	
	private final static Pattern fstruct = Pattern.compile("\\.[_a-zA-Z][_a-zA-Z0-9]*\\s*=\\s[_a-zA-Z][_a-zA-Z0-9]*");
	
	public static List<NameAndType> getFunctionNames(String buffer)
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
