package com.iceberg.cbase.parsers;

import java.util.List;

import com.iceberg.cbase.parsers.options.OptionSimple;
import com.iceberg.cbase.readers.ReaderInterface;
import com.iceberg.cbase.tokens.Token;
import com.iceberg.cbase.tokens.TokenFunctionDecl;
import com.iceberg.cbase.tokens.TokenFunctionDeclSimple;

/**
 * парсер для поиска init и exit макросов и токенов функций
 * в соответствующих макросах
 *
 * @author iceberg
 *
 */
public class ExtendedParserSimple extends ExtendedParser {

	public ExtendedParserSimple(ReaderInterface reader) {
		super(reader);
		addOption(new OptionSimple());
	}

	@Override
	protected Token parseContent(String content, int start, int end) {
		String tokenClearContent = content.trim();
		String nameAndType[] = parseNameAndType(tokenClearContent);
		/* создадим парсер функций */
		ExtendedParserFunction innerParserFunctions = new ExtendedParserFunction(getReader());
		/* и добавим в него поиск только по указанным именам функций */
		innerParserFunctions.addConfigOption("name", nameAndType[0]);
		/* и запустим парсер */
		List<Token> functions = innerParserFunctions.parse();
		if(functions == null || functions.size() == 0)
			return null;
		TokenFunctionDecl oneToken = (TokenFunctionDecl)functions.get(0);
		TokenFunctionDeclSimple token = null;
		if(nameAndType[1].equals("module_init")) {
			token = new TokenFunctionDeclSimple(nameAndType[0],
					oneToken.getRetType(), oneToken.getReplacementParams(),
					oneToken.getBeginIndex() ,
					oneToken.getEndIndex(),
					oneToken.getContent(),
					null,
					TokenFunctionDeclSimple.SimpleType.ST_MODULE_INIT);
		} else
			if(nameAndType[1].equals("module_exit")) {
				token = new TokenFunctionDeclSimple(nameAndType[0],
						oneToken.getRetType(), oneToken.getReplacementParams(),
						oneToken.getBeginIndex() ,
						oneToken.getEndIndex(),
						oneToken.getContent(), 
						null, 
						TokenFunctionDeclSimple.SimpleType.ST_MODULE_EXIT);
		}
		return token;
	}

	private String[] parseNameAndType(String tokenClearContent) {
		String[] nameAndType = new String[2];
		int square_index = tokenClearContent.indexOf("(");
		if(tokenClearContent.contains("module_init") && tokenClearContent.indexOf("module_init")<square_index) {
			nameAndType[0] = tokenClearContent.replaceFirst("module_init\\s*\\(", "").replace(")", "").trim();
			nameAndType[1] = "module_init";
		} else
		if(tokenClearContent.contains("module_exit") && tokenClearContent.indexOf("module_exit")<square_index) {
			nameAndType[0] = tokenClearContent.replaceFirst("module_exit\\s*\\(", "").replace(")", "").trim();
			nameAndType[1] = "module_exit";
		} else
		if(tokenClearContent.contains("subsys_initcall") && tokenClearContent.indexOf("subsys_initcall")<square_index) {
			nameAndType[0] = tokenClearContent.replaceFirst("subsys_initcall\\s*\\(", "").replace(")", "").trim();
			nameAndType[1] = "module_init";
		}

		return nameAndType;
	}

}
