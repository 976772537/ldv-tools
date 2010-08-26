package com.iceberg.cbase.parsers;

import java.util.List;

import com.iceberg.cbase.parsers.ExtendedParserStruct.NameAndType;
import com.iceberg.cbase.parsers.options.OptionSimple;
import com.iceberg.cbase.readers.ReaderInterface;
import com.iceberg.cbase.tokens.TokenFunctionDecl;
import com.iceberg.cbase.tokens.TokenFunctionDeclSimple;

/**
 * парсер для поиска init и exit макросов и токенов функций
 * в соответствующих макросах
 *
 * @author iceberg
 *
 */
public class ExtendedParserSimple extends ExtendedParser<TokenFunctionDeclSimple> {

	public ExtendedParserSimple(ReaderInterface reader) {
		super(reader);
		addOption(new OptionSimple());
	}

	@Override
	protected TokenFunctionDeclSimple parseContent(String content, int start, int end) {
		String tokenClearContent = content.trim();
		NameAndType nameAndType = parseNameAndType(tokenClearContent);
		/* создадим парсер функций */
		ExtendedParserFunction innerParserFunctions = new ExtendedParserFunction(getReader());
		/* и добавим в него поиск только по указанным именам функций */
		innerParserFunctions.addConfigOption("name", nameAndType.getName());
		/* и запустим парсер */
		List<TokenFunctionDecl> functions = innerParserFunctions.parse();
		if(functions == null || functions.size() == 0)
			return null;
		TokenFunctionDecl oneToken = (TokenFunctionDecl)functions.get(0);
		TokenFunctionDeclSimple token = null;
		if(nameAndType.getType().equals("module_init")) {
			token = new TokenFunctionDeclSimple(nameAndType.getName(),
					oneToken.getRetType(), oneToken.getReplacementParams(),
					oneToken.getBeginIndex() ,
					oneToken.getEndIndex(),
					oneToken.getContent(),
					null,
					TokenFunctionDeclSimple.SimpleType.ST_MODULE_INIT);
		} else
			if(nameAndType.getType().equals("module_exit")) {
				token = new TokenFunctionDeclSimple(nameAndType.getName(),
						oneToken.getRetType(), oneToken.getReplacementParams(),
						oneToken.getBeginIndex() ,
						oneToken.getEndIndex(),
						oneToken.getContent(), 
						null, 
						TokenFunctionDeclSimple.SimpleType.ST_MODULE_EXIT);
		}
		return token;
	}

	private NameAndType parseNameAndType(String tokenClearContent) {
		NameAndType nameAndType;
		int square_index = tokenClearContent.indexOf("(");
		if(tokenClearContent.contains("module_init") && tokenClearContent.indexOf("module_init")<square_index) {
			nameAndType = new NameAndType(
					tokenClearContent.replaceFirst("module_init\\s*\\(", "").replace(")", "").trim(),
					"module_init");
		} else
		if(tokenClearContent.contains("module_exit") && tokenClearContent.indexOf("module_exit")<square_index) {
			nameAndType = new NameAndType(
					tokenClearContent.replaceFirst("module_exit\\s*\\(", "").replace(")", "").trim(),
					"module_exit");
		} else
		if(tokenClearContent.contains("subsys_initcall") && tokenClearContent.indexOf("subsys_initcall")<square_index) {
			nameAndType = new NameAndType(
					tokenClearContent.replaceFirst("subsys_initcall\\s*\\(", "").replace(")", "").trim(),
					"module_init");
		} else {
			assert false; 
			nameAndType = null;
		}
		return nameAndType;
	}

}
