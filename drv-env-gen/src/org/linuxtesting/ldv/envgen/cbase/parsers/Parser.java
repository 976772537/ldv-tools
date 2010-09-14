package org.linuxtesting.ldv.envgen.cbase.parsers;

import java.util.List;

import org.linuxtesting.ldv.envgen.cbase.readers.ReaderInterface;
import org.linuxtesting.ldv.envgen.cbase.tokens.Token;


public abstract class Parser<T extends Token> implements ParserInterface<T> {
	protected Parser<T> inputParser = null;
	protected ReaderInterface inputReader = null;
	protected String inputBuffer = null;
	
	/**
	 * из персера вызывается метод parse и достаются токены
	 * @param parser
	 */
	public Parser(Parser<T> parser) {
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
	public abstract List<T> parse();
	
}
