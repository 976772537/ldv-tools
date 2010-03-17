package com.iceberg.cbase.parsers;

import java.util.List;

import com.iceberg.cbase.readers.ReaderInterface;
import com.iceberg.cbase.tokens.Token;

public abstract class Parser implements ParserInterface {
	protected Parser inputParser = null;
	protected ReaderInterface inputReader = null;
	protected String inputBuffer = null;
	
	/**
	 * из персера вызывается метод parse и достаются токены
	 * @param parser
	 */
	public Parser(Parser parser) {
		this.inputParser = parser;	
	}
	
	/**
	 * из ридера вызывается метод readAll и достается строковый буффер,
	 * по которому и проходится парсер
	 * @param reader
	 */
	public Parser(ReaderInterface reader) {
		this.inputReader = reader;
	}

	/**
	 *  Порядок работы метода parse:
	 *  1. Вызывается метод reader.readAll, который читает в буффер содержимое файла
	 *  
	 *  String buffer = null;
		try {
			buffer = inputReader.readAll();
		} catch (IOException e) {
			e.printStackTrace();
			return null;
		}
	 *  
	 *  2. Проверяются - есть ли дополнительные условия к паттерну
	 *     - наличие заранее заданных имен для искомого токена
	 *  3. В зависимости от условий 2 собирается шаблон
	 *  4. Матчится и заполняется список - и, возможно,
	 *     вызываются внутренние парсеры
	 *   
	 * @return
	 */
	public abstract List<Token> parse();
	
}
